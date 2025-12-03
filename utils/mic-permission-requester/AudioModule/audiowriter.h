#pragma once
#include <QObject>
#include <QAudioInput>
#include <QFile>
#include <QAudioRecorder>
#include <QAudioEncoderSettings>
#include <QMimeDatabase>
#include <QAudioProbe>
#include <QMultimedia>
#include <QUrl>

class AudioWriter : public QObject {
    Q_OBJECT
public:
    explicit AudioWriter(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void start(const QString &path) {
        // Configuration inspirée du code que tu m'as donné
        settings.setCodec("audio/x-vorbis");     // GStreamer-compatible
        settings.setSampleRate(44100);
        settings.setChannelCount(2);
       // settings.setEncodingMode(QMultimedia::QualityEncoding);
        settings.setQuality(QMultimedia::NormalQuality);

        rec.setAudioSettings(settings);
        rec.setContainerFormat("audio/ogg");

        // volume par défaut (comme le code d’origine)
        rec.setVolume(0.9);
        rec.setOutputLocation(QUrl::fromLocalFile(path));
        rec.record();
        
        connect(&rec, &QAudioRecorder::stateChanged,
        this, [&](QMediaRecorder::State s){
            if (s == QMediaRecorder::RecordingState) {
                emit started();
            }
        });
    }

    Q_INVOKABLE void stop() {
        rec.stop();
    }
    
    Q_INVOKABLE bool isRecording() const {
        return rec.state() == QMediaRecorder::RecordingState;
    }
    
    Q_INVOKABLE qint64 recordingDuration() const {
    return rec.duration(); // en ms
    }
    
signals:
    void started();    

private:
    QAudioRecorder rec;
    QFile file;
    QAudioEncoderSettings settings;
};
