# ``LZCrashManagerSDK``

一个用于捕获应用崩溃、在崩溃现场尽可能保留执行窗口、持久化崩溃信息，并在下次启动时自动上报到服务端的轻量级 iOS SDK。

## Overview

`LZCrashManagerSDK` 面向需要自行建设崩溃采集链路的客户端项目。SDK 当前聚焦于以下几件事：

- 注册 `NSUncaughtExceptionHandler`，捕获未处理的 Objective-C 异常。
- 在崩溃发生时生成结构化崩溃报告，并写入本地缓存目录。
- 支持可配置的短时线程保活，为崩溃现场的数据整理预留极小窗口。
- 在应用下次启动时扫描未上传的崩溃记录，并通过 HTTP `POST` 自动补传。
- 允许业务层追加公共元信息，例如用户标识、渠道、环境、灰度标记等。

SDK 适合作为你自己的崩溃治理平台的客户端基础层。你可以把它接入到 App 启动流程中，在最早的可控时机完成初始化。

### 工作流程

典型的运行流程如下：

1. 应用启动时创建 ``LZCrashManagerConfiguration``。
2. 通过 ``LZCrashManager/sharedManager`` 调用 ``LZCrashManager/startWithConfiguration:`` 注册崩溃处理逻辑。
3. 如果应用发生未捕获异常，SDK 会生成 ``LZCrashReport``，并将数据写入本地目录。
4. 如果配置了线程保活时间，SDK 会在崩溃线程上短时间维持 RunLoop，以便完成有限的数据整理。
5. 应用下次启动时，SDK 会读取尚未上传的崩溃记录，并调用服务端上报接口。
6. 上传成功的报告会从本地移除，上传失败的报告会保留，等待下次继续重试。

### 快速接入

在应用启动阶段完成如下初始化：

```objc
#import <LZCrashManagerSDK/LZCrashManagerSDK.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSURL *uploadURL = [NSURL URLWithString:@"https://example.com/api/crash/report"];
    LZCrashManagerConfiguration *configuration =
    [LZCrashManagerConfiguration configurationWithUploadURL:uploadURL
                                              appIdentifier:@"com.example.app"
                                                 appVersion:@"1.0.0"];

    configuration.HTTPHeaders = @{
        @"Authorization": @"Bearer token"
    };
    configuration.customParameters = @{
        @"channel": @"AppStore",
        @"environment": @"production"
    };
    configuration.crashThreadKeepAliveDuration = 2.0;
    configuration.maxStoredCrashReportCount = 20;

    [LZCrashManager sharedManager].delegate = self;
    [[LZCrashManager sharedManager] startWithConfiguration:configuration];
    return YES;
}
```

如果你希望在业务侧补充更多上下文信息，可以实现 ``LZCrashManagerDelegate``：

```objc
- (NSDictionary<NSString *,id> *)crashManagerAdditionalMetadata {
    return @{
        @"user_id": @"123456",
        @"login_state": @"logged_in",
        @"current_page": @"HomeViewController"
    };
}
```

### 上报数据说明

SDK 生成的崩溃报告以 ``LZCrashReport`` 为核心抽象，通常包含以下内容：

- 崩溃记录唯一标识。
- 崩溃类型，例如 `exception`。
- 崩溃原因。
- 崩溃线程名称。
- 调用栈符号数组。
- 崩溃发生时间。
- 运行时元信息。

最终上报时，SDK 还会自动合并配置中的应用维度信息，例如：

- `app_identifier`
- `app_version`
- 业务自定义参数

服务端可以直接按 JSON 结构接收并落库，再进一步做聚合、告警或分析。

### 存储与重试策略

崩溃报告会先写入本地缓存目录，再等待后续时机上传。这种设计有几个好处：

- 即使崩溃时网络不可用，也不会丢失核心信息。
- 即使应用立即退出，也能在下一次启动时继续补传。
- 上传失败的记录不会立刻删除，能够自然形成重试机制。

为了避免本地文件无限增长，SDK 支持通过 ``LZCrashManagerConfiguration/maxStoredCrashReportCount`` 限制缓存数量。超过阈值时，较早的报告会被优先清理。

### 线程保活说明

`崩溃后线程保活` 是一个很敏感的能力。SDK 当前通过短时间维持 RunLoop 的方式，尽可能在异常发生后保留一个极小的执行窗口。这个能力适用于：

- 整理少量内存中已经准备好的崩溃上下文。
- 确保本地落盘逻辑有机会执行完成。

不建议依赖该窗口执行复杂逻辑，例如：

- 大量磁盘 IO
- 复杂对象遍历
- 同步网络请求
- 需要强一致性的业务恢复操作

崩溃现场本身已经不稳定，因此所有操作都应尽量保持简单、快速、幂等。

### Signal 捕获的当前状态

SDK 已预留对 Unix Signal 的处理能力配置项，但默认关闭。原因是 Signal 场景对“异步信号安全”要求非常高，而许多 Foundation 和 Objective-C 运行时能力并不适合直接在 Signal Handler 中调用。

如果你后续希望扩展到 `SIGABRT`、`SIGSEGV` 等更底层崩溃场景，建议在现有异常捕获链路稳定之后，再引入专门的低层安全实现。

### 最佳实践

- 尽量在应用启动早期初始化 SDK。
- 将上报接口设计为幂等，避免重复上报带来的脏数据。
- 在服务端保留 `identifier`、`timestamp`、`app_version` 等索引字段，便于检索和聚合。
- 通过 delegate 注入稳定、低成本的元信息，不要在回调中执行复杂逻辑。
- 先使用异常捕获链路完成闭环，再逐步扩展更复杂的崩溃场景。

### 限制说明

当前版本主要覆盖未处理的 Objective-C 异常及其落盘、补传能力。对于以下场景，仍需要后续增强：

- Mach 异常级别的更底层崩溃捕获。
- 更严格的 Signal 安全处理。
- 二进制堆栈地址与符号化平台的完整联动。
- 更丰富的设备信息、线程信息和运行现场快照。

## Topics

### Core APIs

- ``LZCrashManager``
- ``LZCrashManagerDelegate``

### Configuration

- ``LZCrashManagerConfiguration``

### Models

- ``LZCrashReport``
