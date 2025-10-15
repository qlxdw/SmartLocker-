import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.12
import QtQuick.Layouts 1.0
import QtQuick.VirtualKeyboard 2.0
Item {
    id: pickup
    width: 1024
    height: 600
    visible: true

    Column {
        spacing: 10
        width: parent.width
        anchors.top: parent.top
        anchors.topMargin: 40
        Image {
            id: myImage
            width: parent.width
            fillMode: Image.PreserveAspectFit
            Component.onCompleted: {
                // 动态设置图片路径
                //myImage.source = "qrc:/delivery.png";
            }
        }
        TextField {

            id: codeNumberField

            //height: 60
            //implicitHeight: height  // 确保隐式高度同步
            anchors.horizontalCenter: parent.horizontalCenter

            font.pixelSize: 28
            validator: RegExpValidator {
                regExp: /^[0-9\+\-\#\*\ ]{6,}$/
            }
            width: parent.width * 0.8
            placeholderText: "取件码："
            inputMethodHints: Qt.ImhDialableCharactersOnly
            onAccepted: formattedNumberField.focus = true
        }
        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            Button {
                text: "取 件"
                font.pixelSize: 30
                enabled: stack.depth > 1
                onClicked: {
                    // 取件码不能为空
                    if(codeNumberField.text === "") {
                        receivedMessage.text = "取件码不能为空"
                    } else if (codeNumberField.text.length !== 8){ // 取件码位数不够
                        receivedMessage.text = "取件码位数不够"
                    } else {
                        receivedMessage.text = "发送消息"
                        udpClient.sendMessage('p'+codeNumberField.text+'\0', host, port)
                    }
                    //stack.pop()
                }
            }
            Button {
                text: "取 消"
                font.pixelSize: 30
                enabled: stack.depth > 1
                onClicked: stack.pop()
            }
        }



        // 显示接收到的消息
        Text {
            id: receivedMessage
            text: "Received message: 取件码为8位" // 初始化文本
        }
        // 连接 udpClient 的 messageReceived 信号，当有新消息时更新显示
//        Connections {
//            target: udpClient
//            function onMsgPickup(message) {
//                receivedMessage.text = "Received message: " + message
//            }
//        }


        Component.onCompleted: {
            udpClient.msgPickup.connect(function(message) {
                //receivedMessage.text = "Received message: " + message
                if(message === "1"){
                receivedMessage.text = "Received message: " + "未查询到该快递或该快递已被取出！"
                }
                else{
                receivedMessage.text = "Received message: " + "快递号为" + message + "的快递被取出！"
                }

            })
        }


    }

    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: pickup.height
        width: pickup.width

        states: State {
            name: "visible"
            when: inputPanel.active
            PropertyChanges {
                target: inputPanel
                y: pickup.height - inputPanel.height
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
