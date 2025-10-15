import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.12
import QtQuick.Layouts 1.0
import QtQuick.VirtualKeyboard 2.0

Item {
    id: login // 登录页面的根元素
    width: 1024// 600为 480 像素
    height: 600//设为 854 像素
    visible: true // 设置页面可见

    // 新增：键盘激活状态跟踪属性
    property bool keyboardActive: false
    property string lastMessage: ""

    MouseArea {
        anchors.fill: parent//与父组件范围一致
        enabled: keyboardActive//键盘在的时候生效
        onClicked: {
            phoneNumberField.focus = false
            passwordField.focus = false
            Qt.inputMethod.hide()//收起键盘
        }
    }

    Image {
        id: myImage // 图片元素
        width: parent.width * 0.2 // 图片宽度为父元素宽度
        fillMode: Image.PreserveAspectFit // 保持宽高比填充图片
        anchors.horizontalCenter: parent.horizontalCenter
        height: 120
        Component.onCompleted: {
            // 动态设置图片路径
            //myImage.source = "qrc:/delivery.png"; // 设置图片源
        }
    }

    Column {
        spacing: 10 // 列之间的间距
        width: parent.width // 列宽度为父元素宽度
        //anchors.centerIn: parent // 将列居中对齐
        anchors.top: parent.top
        anchors.topMargin: 20  // 控制整体上移距离

        Label {
            height: 60
            text: "快 递 员 登 录" // 登录标题
            anchors.horizontalCenter: parent.horizontalCenter // 水平居中对齐
            font.pixelSize: 28 // 设置字体大小为 28 像素
        }

        TextField {
            id: phoneNumberField // 手机号输入框
            anchors.horizontalCenter: parent.horizontalCenter // 水平居中对齐
            font.pixelSize: 25 // 设置字体大小为 25 像素
            // 设置输入格式验证：仅允许数字和某些符号，长度至少为 6
            validator: RegExpValidator {
                regExp: /^[0-9\+\-\#\*\ ]{6,}$/
            }
            width: parent.width * 0.6// 设置宽度为父元素的 80%
            placeholderText: "手机号" // 输入框提示文本
            inputMethodHints: Qt.ImhDialableCharactersOnly // 只允许输入可拨号字符
            // 修改：添加焦点变化处理
            onActiveFocusChanged: {
                keyboardActive = activeFocus
                if (activeFocus) {
                    Qt.inputMethod.show()
                } else {
                    Qt.inputMethod.hide()
                }
            }
            onAccepted: passwordField.focus = true // 输入完成后，聚焦到下一个输入框
        }

        TextField {
            id: passwordField // 密码输入框
            anchors.horizontalCenter: parent.horizontalCenter // 水平居中对齐
            font.pixelSize: 28 // 设置字体大小为 28 像素
            width: parent.width * 0.6// 设置宽度为父元素的 80%
            echoMode: TextInput.Password // 设置输入模式为密码模式
            placeholderText: "密 码" // 输入框提示文本
            // 设置输入提示：不自动大写、优先使用小写、敏感数据、不建议自动填充
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            // 修改：添加焦点变化处理
            onActiveFocusChanged: keyboardActive = activeFocus
            onAccepted: upperCaseField.focus = true // 输入完成后，聚焦到下一个输入框
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter // 水平居中对齐
            spacing: 10 // 按钮之间的间距

            Button {
                text: "登 录" // 登录按钮文本
                font.pixelSize: 25 // 设置字体大小为 25 像素
                onClicked: {
                    // 先移除焦点再跳转
                    //phoneNumberField.focus = false
                    //passwordField.focus = false
                    // 手机号或密码不能为空
                    if(phoneNumberField.text === "" || passwordField.text === "") {
                        receivedMessage.text = "手机号或密码不能为空"
                    } else if (phoneNumberField.text.length !== 11){ // 手机号格式不对
                        receivedMessage.text = "手机号格式不对"
                    } else {
                        receivedMessage.text = "发送消息"
                        udpClient.sendMessage('l'+phoneNumberField.text+'\0'+passwordField.text+'\0', host, port)
                        //stack.push("qrc:/delivery.qml")
                    }
                }

            }

            Button {
                text: "取 消" // 取消按钮文本
                font.pixelSize: 25 // 设置字体大小为 25 像素
                enabled: stack.depth > 1 // 只有在有多个页面时才能点击
                onClicked: stack.pop() // 点击后返回上一个页面
            }

            Button {
                text: "注 册" // 注册按钮文本
                font.pixelSize: 25 // 设置字体大小为 25 像素
                onClicked: stack.push("qrc:/register.qml") // 点击后切换到注册页面
            }

//            Button {
//                text: "手动测试信号"
//                font.pixelSize: 25 // 设置字体大小为 25 像素
//                onClicked: {
//                    console.log("尝试手动触发信号");
//                    udpClient.msgLogin("test_message"); // 直接调用信号
//                }
//            }
        }
        // 显示接收到的消息
        Text {
            id: receivedMessage
            text: "Received message: " // 初始化文本
        }
        // 连接 udpClient 的 messageReceived 信号，当有新消息时更新显示
//        Connections {
//            target: udpClient

//            function onMsgLogin(message) {
//                console.log("[QML] udpClient 地址:", udpClient)
//                console.log("信号接收者数量:", udpClient.receivers("msgLogin"))
//                console.log("[QML] 收到信号:", message)
//                receivedMessage.text = "Received message: " + message
//                if(message === "ok")
//                    stack.push("qrc:/delivery.qml")
//            }
//        }

        Component.onCompleted: {
            udpClient.msgLogin.connect(function(message) {
                receivedMessage.text = "Received message: " + message
                if(message === "ok")
                    stack.push("qrc:/delivery.qml")
            })
        }


    }

    // 新增：键盘面板背景（保持与示例代码一致的结构）
    Rectangle {
        id: keyboardPanelBg
        z: 88
        width: parent.width
        anchors.bottom: inputPanel.top
        height: keyboardActive ? 28 * login.height / 480 : 0
        color: "transparent"
        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }
    }

    // 修改后的输入面板（保留原有注释并优化实现）
    InputPanel {
        id: inputPanel
        z: 99
        width: parent.width
        y: Qt.inputMethod.visible ? parent.height - height : parent.height

        // 与系统输入法状态绑定
        active: Qt.inputMethod.visible

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }
    }
}
