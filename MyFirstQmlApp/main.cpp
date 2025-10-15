#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QScreen>
#include <QQuickTransform>
#include <QMatrix4x4>  // 添加这行
#include "udpclient.h"
#include <QQmlContext>  // 必须包含此头文件
#include <QQmlEngine>   // 如果使用QQmlEngine也需要

struct MyTransform : public QQuickTransform {
    MyTransform(QSizeF size) {
        tr_.rotate(270);
        tr_ *= QTransform::fromTranslate(0, size.width());
    }
    virtual void applyTo(QMatrix4x4 *matrix) const {
        QMatrix4x4 trMatrix(tr_);  // 将 QTransform 转换为 QMatrix4x4
        *matrix = (*matrix) * trMatrix;  // 现在可以正确相乘
    }
    QTransform tr_;
};

UdpClient udpClient;


int main(int argc, char *argv[]) {
    //QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QGuiApplication app(argc, argv);



    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("udpClient", &udpClient);
    const QUrl url(QStringLiteral("qrc:/main.qml"));

    // 加载 QML 并检查错误
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical("Failed to load QML file: %s", qPrintable(url.toString()));
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);



    return app.exec();
}



