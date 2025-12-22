#pragma once

#include <QObject>
#include <QString>
#include <QProcess>

class UploadHelper : public QObject
{

    Q_PROPERTY(QString blob_path READ get_blob_path WRITE set_blob_path)
    Q_OBJECT
public:
    explicit UploadHelper(QObject *parent = nullptr) : QObject(parent) {}

    QString get_blob_path();
    void set_blob_path(QString value);
    Q_INVOKABLE void uploadFile( QString path );
private:
    QString blob_path;
};
