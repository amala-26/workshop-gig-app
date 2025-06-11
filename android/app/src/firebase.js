// src/firebase.js
import firebase from 'firebase/app';
import 'firebase/auth';
// Add other services as needed: 'firebase/firestore', 'firebase/storage', etc.

const firebaseConfig = {
    apiKey: "AIzaSyAXRzC1tGVi1LUj4DLGsMuvKaIt2apuOw4",
    authDomain: "workshop-gig-app.firebaseapp.com",
    projectId: "workshop-gig-app",
    storageBucket: "workshop-gig-app.firebasestorage.app",
    messagingSenderId: "1014195525225",
    appId: "1:1014195525225:web:f30e280a39a73a359eb4f8",
    measurementId: "G-PP2HR0RMVF"
};

firebase.initializeApp(firebaseConfig);

export default firebase;
