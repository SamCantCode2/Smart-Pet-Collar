#include "DHT.h"
#include "MAX30105.h"
#include "MPU9250.h"
#include <Adafruit_Sensor.h>
#include <Wire.h>
#include "BluetoothSerial.h"
#include "heartRate.h"
#include "spo2_algorithm.h"

const int DHTPIN = 25;
const int DHTTYPE = 11;
const int SUNPIN = 35;

DHT dht(DHTPIN, DHTTYPE);
MAX30105 particleSensor;
MPU9250 IMU(Wire, 0x68);
float hum, temp, bpm;
long lastbeat = 0;

BluetoothSerial bt;

void setup() {
  Serial.begin(115200);
  dht.begin();
  Wire.begin(21, 22);
  while(!particleSensor.begin(Wire, 0x57)){
    Serial.println("MAX30102 not found");
    delay(100);
  }
  Serial.println("MAX30102 initialized");
  particleSensor.setup();                     
  particleSensor.setPulseAmplitudeRed(0x0A);  
  particleSensor.setPulseAmplitudeGreen(0);
 while(!IMU.begin()){
    Serial.println("MPU9250 not found");
    delay(100);
  }
  Serial.println("MPU9250 initialized");
  IMU.setAccelRange(MPU9250::ACCEL_RANGE_16G);
  IMU.setGyroRange(MPU9250::GYRO_RANGE_2000DPS);
  IMU.setDlpfBandwidth(MPU9250::DLPF_BANDWIDTH_184HZ);
  IMU.setSrd(19);
  bt.begin("ESP32");
  Serial.println("Ready to pair");
  while (!bt.available()){
    Serial.println("Device not found");
    delay(1000);
  }
  Serial.println("Connection established");
  Serial.println("Message: " + String(bt.readString()));
}

void loop() {
  // put your main code here, to run repeatedly:
  if(!bt.connected()){
    Serial.println("Connection lost");
  }
  else{
    long irval = particleSensor.getIR();
    if (irval < 75000){
      Serial.println("No object detected");
      delay(1000);
      return;
    }
    hum = dht.readHumidity();
    temp = dht.readTemperature();
    Serial.println("Humidity:" + String(hum));
    Serial.println("Temperature:" + String(temp));
    int sunlight = digitalRead(35);
    if(checkForBeat(irval) == true){
      long delta = millis() - lastbeat;
      lastbeat = millis();
      bpm = 60/(delta / 1000);
    }
    if (sunlight == HIGH){
      sunlight = 1;
    }
    else{
      sunlight = 0;
    }
    Serial.println("Sunlight:" + String(sunlight));
    IMU.readSensor();
    Serial.print(IMU.getAccelX_mss(), 6);
    Serial.print("\t");
    Serial.print(IMU.getAccelY_mss(), 6);
    Serial.print("\t");
    Serial.print(IMU.getAccelZ_mss(), 6);
    Serial.print("\t");
    Serial.print(IMU.getGyroX_rads(), 6);
    Serial.print("\t");
    Serial.print(IMU.getGyroY_rads(), 6);
    Serial.print("\t");
    Serial.print(IMU.getGyroZ_rads(), 6);
    Serial.print("\t");
    Serial.print(IMU.getMagX_uT(), 6);
    Serial.print("\t");
    Serial.print(IMU.getMagY_uT(), 6);
    Serial.print("\t");
    Serial.print(IMU.getMagZ_uT(), 6);
    Serial.print("\t");
    Serial.println(IMU.getTemperature_C(), 6);
    String msg = String(hum) + " " + String(temp) + " " + String(bpm) + " " + String(sunlight) + " " + String(IMU.getAccelX_mss(), 6) + " " + String(IMU.getAccelY_mss(), 6) + " " + String(IMU.getAccelZ_mss(), 6) + " " + String(IMU.getTemperature_C(), 6);
    bt.println(msg);
  }
  delay(100);
}