import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.12
import QtQuick.Layouts 1.0
import QtQuick.VirtualKeyboard 2.0

Item {
    id: delivery
    property string cabinet_size: '0'
    width: 1024
    height: 600
    visible: true
    Image {
        id: myImage
        width: parent.width
        fillMode: Image.PreserveAspectFit
        Component.onCompleted: {
            // 动态设置图片路径
            //myImage.source = "qrc:/delivery.png";
        }
    }
    Column {
        spacing: 10
        width: parent.width
        //anchors.centerIn: parent
        Label {
            text: "快 递 员 投 递"
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 28
        }
        TextField {
            id: parcelField
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 25
            validator: RegExpValidator {
                regExp: /^[0-9\+\-\#\*\ ]{6,}$/
            }
            width: parent.width * 0.8
            placeholderText: "包裹号"
            inputMethodHints: Qt.ImhDialableCharactersOnly
            onAccepted: formattedNumberField.focus = true
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
            id: phoneNumberField2
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 25
            validator: RegExpValidator {
                regExp: /^[0-9\+\-\#\*\ ]{6,}$/
            }
            width: parent.width * 0.8
            placeholderText: "确认手机号"
            inputMethodHints: Qt.ImhDialableCharactersOnly
            onAccepted: formattedNumberField.focus = true
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8
            RadioButton {
                id: cabinet_large
                font.pixelSize: 25
                text: "大柜"
                checked: true  // 默认选中
                onClicked: cabinet_size = '2'
            }

            RadioButton {
                id: cabinet_medium
                font.pixelSize: 25
                text: "中柜"
                onClicked: cabinet_size = '1'
            }

            RadioButton {
                id: cabinet_small
                font.pixelSize: 25
                text: "小柜"
                onClicked: cabinet_size = '0'
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Button {
                text: "投 递"
                font.pixelSize: 25
                onClicked: {
                    // 手机号或包裹号不能为空
                    if(phoneNumberField.text === "" || parcelField.text === "") {
                        receivedMessage.text = "手机号或包裹号不能为空"
                    } else if (phoneNumberField.text.length !== 11){ // 手机号格式不对
                        receivedMessage.text = "手机号格式不对"
                    } else if (parcelField.text.length !== 8){ // 包裹号格式不对
                            receivedMessage.text = "包裹号格式不对"
                    } else if (phoneNumberField.text !== phoneNumberField2.text){ // 两次输入的手机号不一致
                        receivedMessage.text = "两次输入的手机号不一致"
                    } else {
                        receivedMessage.text = "发送消息"
                        udpClient.sendMessage('d'+cabinet_size+parcelField.text+'\0'+phoneNumberField.text+'\0', host, port)
                    }
                }
            }
            Button {
                text: "取 消"
                font.pixelSize: 25
                onClicked: {
                stack.pop()
                stack.pop()
                }
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
//            function onMsgDelivery(message) {
//                receivedMessage.text = "Received message: " + message
//            }
//        }

        Component.onCompleted: {
            udpClient.msgDelivery.connect(function(message) {
                receivedMessage.text = "Received message: " + "已存入" + message + "号柜子"

            })
        }


    }

    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: delivery.height
        width: delivery.width

        states: State {
            name: "visible"
            when: inputPanel.active
            PropertyChanges {
                target: inputPanel
                y: delivery.height - inputPanel.height
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
