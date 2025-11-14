#include <QGuiApplication>
#include <QScreen>
#include <QDebug>
#include <iostream>
using namespace std;

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    QScreen *screen = QGuiApplication::primaryScreen();
    qreal dpi =  screen->logicalDotsPerInch();  // Moyenne approximative
    cout << dpi <<endl;

    return 0;
}
