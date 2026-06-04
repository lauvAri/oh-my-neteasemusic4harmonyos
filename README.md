后端API部署在 https://1326430649-cz7h9y1id3.ap-guangzhou.tencentscf.com

API 文档：https://docs-neteasecloudmusicapi.focalors.ltd/#/

构建项目(如果你的 DecEco Studio 没有安装在默认位置，请根据实际情况替换下列命令)

```bash
"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```