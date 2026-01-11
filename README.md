
# 👣 Footsteps Energy Generator

This project demonstrates a **Footsteps Energy Generator system** that converts mechanical energy from human footsteps into electrical energy using **piezoelectric sensors**.  
The generated voltage is measured, processed, and displayed in real time using a **16x2 I2C LCD**, along with a **bar graph visualization** and **step counter**.

---

## 📌 Project Overview

Footsteps Energy Generator is an energy harvesting system designed to generate small electrical power from walking or stepping actions.  
Each footstep produces electrical pulses through piezo sensors, which are rectified and scaled before being read by a microcontroller.

The system detects footsteps, measures the generated voltage in millivolts, displays it visually, and maintains a running count of steps.

---

## 🚀 Features

- Real-time voltage measurement from piezoelectric sensors  
- Displays voltage (mV) on 16x2 I2C LCD  
- Professional bar graph visualization on LCD  
- Real-time footstep detection  
- Step counter with debounce protection  
- Adjustable step sensitivity  
- LED indication for detected footsteps  
- Auto baseline calibration at startup  
- Serial output for debugging and calibration  

---

## 🛠️ Hardware Components Used

- Microcontroller (Arduino / ESP-based board)  
- Piezoelectric sensor(s)  
- 16x2 I2C LCD display  
- Rectifier circuit (diodes)  
- Resistor divider network  
- LED  
- Connecting wires  
- Power supply  

---

## 💻 Software & Tools Used

- Arduino IDE  
- Embedded C / Arduino programming  
- LiquidCrystal_I2C library  
- Wire (I2C communication)  

---

## 🧩 Environment Setup

Before uploading and running the program, the environment must be properly set up.

- Install **Arduino IDE**
- Add required board support package (if using ESP board)
- Install **LiquidCrystal_I2C** library
- Select correct board and COM port
- Connect hardware as per circuit diagram

After completing the setup, upload the program to the microcontroller.

---

## ▶️ How the Program Works

1. Piezo sensors generate voltage when pressure is applied  
2. The voltage is rectified and scaled using a resistor divider  
3. The microcontroller reads the voltage through ADC  
4. Voltage is converted into millivolts  
5. LCD displays voltage, step count, and bar graph  
6. Step detection algorithm identifies valid footsteps  
7. LED blinks for every detected step  
8. Baseline voltage is continuously updated for accuracy  

---

## 📊 Display Information

**LCD First Line**
- Voltage in millivolts (mV)
- Total step count

**LCD Second Line**
- Dynamic bar graph representing voltage level

---

## ⚙️ Adjustable Parameters

- Step sensitivity (0–100%)
- Visual bar graph gain
- Step debounce time
- LED ON duration
- Dynamic threshold enable/disable

---

## 📌 Applications

- Energy harvesting systems  
- Smart flooring solutions  
- Green energy projects  
- Educational and academic projects  
- Smart city infrastructure  

---

## 🔮 Future Enhancements

- Battery charging and storage system  
- Wireless data transmission  
- Power optimization techniques  
- Multiple piezo sensor integration  
- IoT-based monitoring  


