import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.12
import QtQuick.Layouts 1.0
import QtQuick.VirtualKeyboard 2.0

Item {
    id: register
    property string company: ""
    width: 1024
    height: 600
    visible: true
    Image {
        id: myImage
        width: parent.width * 0.2
        fillMode: Image.PreserveAspectFit
        Component.onCompleted: {
            // 动态设置图片路径
            //myImage.source = "qrc:/delivery.png";
        }
    }
    Column {
        spacing: 10
        width: parent.width
        anchors.centerIn: parent
        Label {
            text: "快 递 员 注 册"
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 28
        }
        TextField {
            id: phoneNumberField
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 25
            validator: RegExpValidator {
                regExp: /^[0-9\+\-\#\*\ ]{6,}$/
            }
            width: parent.width * 0.8
            placeholderText: "手机号"
            inputMethodHints: Qt.ImhDialableCharactersOnly
            onAccepted: formattedNumberField.focus = true
        }
        TextField {
            id: passwordField
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 25
            width: parent.width * 0.8
            echoMode: TextInput.Password
            placeholderText: "密 码"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            onAccepted: upperCaseField.focus = true
        }
        TextField {
            id: passwordField2
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 25
            width: parent.width * 0.8
            echoMode: TextInput.Password
            placeholderText: "确认密码"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            onAccepted: upperCaseField.focus = true
        }
        ComboBox {
            id: courierSelector
            width: 200

            // 使用列表模型和相关的模型数据
            ListModel {
                id: courierList
                ListElement { code: "JD"; name: "京东快递" }
                ListElement { code: "SF"; name: "顺丰速运" }
                ListElement { code: "STO"; name: "百世汇通" }
                ListElement { code: "ST"; name: "申通快递" }
                ListElement { code: "YTO"; name: "圆通速递" }
                ListElement { code: "EMS"; name: "邮政EMS" }
                ListElement { code: "SEE"; name: "速尔快递" }
                ListElement { code: "DBL"; name: "德邦快递" }
                ListElement { code: "UC"; name: "优速快递" }
                ListElement { code: "KT"; name: "快捷快递" }
                ListElement { code: "JT"; name: "极兔快递" }
            }

            // 设置模型和文本角色
            model: courierList
            textRole: "name"

            // 当前索引变化时的处理
            onCurrentIndexChanged: {
                // 输出当前选中的公司代码和名称
                console.log("当前选中的快递公司: ", courierList.get(currentIndex).code, courierList.get(currentIndex).name)
                company = courierList.get(currentIndex).name
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Button {
                text: "注 册"
                font.pixelSize: 25
                enabled: stack.depth > 1
                onClicked: {
                    // 注册信息不能为空
                    if(phoneNumberField.text === "" || passwordField.text === "" || passwordField2.text === "") {
                        receivedMessage.text = "注册信息不能为空"
                    } else if (phoneNumberField.text.length !== 11){ // 手机号格式不对
                        receivedMessage.text = "手机号格式不对"
                    } else if (passwordField.text !== passwordField2.text){ // 两次输入的密码不一致
                        receivedMessage.text = "两次输入的密码不一致"
                    } else {
                        receivedMessage.text = "发送消息"
                        udpClient.sendMessage('r'+phoneNumberField.text+'\0'+passwordField.text+'\0'+company+'\0', host, port)
                    }
                }
            }
            Button {
                text: "取 消"
                font.pixelSize: 25
                enabled: stack.depth > 1
                onClicked: stack.pop()
            }
        }



        // 显示接收到的消息
        Text {
            id: receivedMessage
            text: "Received message: " // 初始化文本
        }
        // 连接 udpClient 的 messageReceived 信号，当有新消息时更新显示
//        Connections {
//            target: udpClient
//            function onMsgRegister(message) {
//                receivedMessage.text = "Received message: " + message
//            }
//        }

        Component.onCompleted: {
            udpClient.msgRegister.connect(function(message) {
                receivedMessage.text = "Received message: " + message
                stack.pop()

            })
        }


    }

    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: register.height
        width: register.width

        states: State {
            name: "visible"
            when: inputPanel.active
            PropertyChanges {
                target: inputPanel
                y: register.height - inputPanel.height
            }
        }
        transitions: Transition {
            from: ""
            to: "visible"
            reversible: true
            ParallelAnimation {
                NumberAnimation {
                    properties: "y"
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
