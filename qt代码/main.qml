import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.12
import QtQuick.Layouts 1.0
import QtQuick.VirtualKeyboard 2.2

Window { // 创建一个窗口
    id: window // 窗口的唯一标识符
    width: 1024 // 窗口的宽度
    height: 600 // 窗口的高度
    visible: true // 窗口的可见性设置为 true

    property int text_size: 25
    property int spacing_value: 10
    property string host: "192.168.1.29"
    property int port: 8888


            StackView { // 使用 StackView 组件用于管理视图堆栈
                    id: stack // StackView 的唯一标识符
                    initialItem: mainView // 初始显示的视图是 mainView
                    anchors.fill: parent // StackView 填充整个窗口
                }

                Component { // 定义一个组件
                    id: mainView // 组件的唯一标识符

                    Column { // 使用 Column 布局，垂直排列子项
                        spacing: 80 // 子项之间的间距为 20
                        topPadding: 100  // 控制第一个元素与顶部的距离

                        Image { // 显示图片的组件
                            id: myImage // 图片组件的唯一标识符
                            width: parent.width * 0.2 // 图片的宽度与父容器相同
                            fillMode: Image.PreserveAspectFit // 保持图片纵横比进行缩放
                            anchors.horizontalCenter: parent.horizontalCenter
                            Component.onCompleted: { // 当组件加载完成后执行
                                // 动态设置图片路径
                                myImage.source = "qrc:/delivery.png"; // 设置图片来源
                            }
                        }

                        Button { // 按钮组件
                            width: parent.width * 0.5 // 按钮宽度为父容器宽度的 50%
                            anchors.horizontalCenter: parent.horizontalCenter

                            contentItem: Text { // 按钮的内容为文本
                                id: button_delivery // 文本的唯一标识符
                                text: qsTr("投 递") // 按钮上显示的文本
                                font.pixelSize: 25 // 文本的字体大小为 25 像素
                                // 设置水平对齐方式
                                horizontalAlignment: Text.AlignHCenter // 文本水平居中对齐
                            }
                            onClicked: stack.push("qrc:/login.qml") // 按钮点击时推送新的视图到 StackView
                        }

                        Button { // 另一个按钮组件
                            width: parent.width * 0.5 // 按钮宽度为父容器宽度的 50%
                            anchors.horizontalCenter: parent.horizontalCenter

                            contentItem: Text { // 按钮的内容为文本
                                id: button_pickup // 文本的唯一标识符
                                text: qsTr("取 件") // 按钮上显示的文本
                                font.pixelSize: 25 // 文本的字体大小为 25 像素
                                // 设置水平对齐方式
                                horizontalAlignment: Text.AlignHCenter // 文本水平居中对齐
                            }
                            onClicked: stack.push("qrc:/pickup.qml") // 按钮点击时推送新的视图到 StackView
                        }
                    }
                }

}
