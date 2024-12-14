# Event Management Mobile App  

This is a Flutter-based mobile application designed to simplify event creation, management, and participation. The app integrates Google and phone authentication to ensure secure user access and employs the Google Places API to provide an intuitive venue selection experience. Users can create, join, and manage events effortlessly, with real-time location suggestions or the option to use their current location.

---

## **Features**  

### **1. Authentication**  
Securely authenticate users via two robust methods:  
- **Google Sign-In**:  
  - Integrates GoogleSignIn API for effortless login with Google accounts.  
  - Ensures fast onboarding with access to profile information like name, email, and profile picture.  

- **Phone Authentication**:  
  - After Google sign-in users have to log in using their phone numbers with OTP-based verification.  
  - Accessible for all, providing universal compatibility.  

---

### **2. Event Management**  
Simplifies event handling through:  
- **Create Events**:  
  - Specify event name, date, time, location, and attendee limits, related tags and theme. 
  - Integrates location selection with Google Places API or user GPS.  

- **Join Events**:  
  - Users can join events by giving location to application, app will fetch nearby events.
  - A join request will be send to Host, users can cancel their join request at anytime .
  - Designed for effortless participation in shared events.  

- **Manage Events**:  
  - Event organizers can edit, update, or cancel events.
  - Event organizers can reject join request.  
  - Track participation and attendee responses in real-time.  

---

### **3. Venue Selection**  
Efficiently select venues with:  
- **Google Places API Integration**:  
  - Provides dynamic, real-time location suggestions based on user input.  
  - Ensures accurate venue selection, reducing manual errors.  

- **Current Location**:  
  - Users can select their GPS-based current location with a single tap.  
  - Ideal for impromptu or ad hoc events.  

- **Real-Time Suggestions**:  
  - Dynamically updates venue suggestions for relevant and precise choices.  

---

## **Technology Stack**  
- **Frameworks**: Flutter, Dart  
- **Authentication**: Google Firebase, GoogleSignIn API  
- **APIs**: Google Places API  
- **Storage**: Firebase Realtime Database  
---
## **Preview**
https://github.com/user-attachments/assets/a7de97ac-4d62-46cc-bf20-74abbe4f6802


