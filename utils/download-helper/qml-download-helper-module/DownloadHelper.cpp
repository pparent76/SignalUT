#include "DownloadHelper.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QByteArray>
#include <QDebug>
#include <QDirIterator>
#include <QDateTime>


QString findNewestFile(const QString &dirPath) {
    QDir dir(dirPath);
    QFileInfo newestFile;
    qint64 newestTime = 0;

    // Ne liste que les fichiers du dossier courant
    QFileInfoList files = dir.entryInfoList(
        QDir::Files,
        QDir::Time | QDir::Reversed // du plus récent au plus ancien
    );

    for (const QFileInfo &fi : files) {
        qint64 mtime = fi.lastModified().toSecsSinceEpoch();
        if (mtime > newestTime) {
            newestTime = mtime;
            newestFile = fi;
        }
    }

    if (!newestFile.exists()) {
        qWarning() << "No file found in" << dirPath;
        return "";
    }

    return newestFile.absoluteFilePath();
}

void clearCache(const QString &dirPath, const QString &fileToKeep)
{
    QDirIterator it(dirPath, QDir::Files, QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        QFileInfo fi = it.fileInfo();

        // Vérifie que le fichier a une extension
        const QString fileName = fi.fileName();
        bool hasExtension = fileName.contains('.') && !fileName.startsWith('.');

        // Ignore if does not have extension or is file to keep
        if (!hasExtension || fi.absoluteFilePath() == fileToKeep)
            continue;

        // Ignore symlinks
        if (fi.isSymLink())
            continue;
        
        // Supprime le fichier
        QFile file(fi.absoluteFilePath());
        if (!file.remove()) {
            qWarning() << "Could not delete" << fi.absoluteFilePath();
        } else {
            qDebug() << "Deleted :" << fi.absoluteFilePath();
        }
    }
}

QString DownloadHelper::getLastDownloaded()
{

    QString dirPath = blob_path;
    QString newestFilePath = findNewestFile(dirPath);
    clearCache(dirPath,newestFilePath);
    if (newestFilePath.isEmpty())
        return "Error File empty";
    
    return newestFilePath;
}


QString DownloadHelper::get_blob_path() 
{ return blob_path; }
   
void DownloadHelper::set_blob_path(QString value)
{ blob_path = value; }
 


