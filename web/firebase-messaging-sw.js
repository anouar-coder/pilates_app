// web/firebase-messaging-sw.js
// Version avec importScripts corrigée
try {
  importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
  importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

  firebase.initializeApp({
    apiKey: "AIzaSyCHrLdhc8_x5MQSZC8x3iFBS5QX1WKD7Po",
    authDomain: "pilates-app-4430c.firebaseapp.com",
    projectId: "pilates-app-4430c",
    storageBucket: "pilates-app-4430c.firebasestorage.app",
    messagingSenderId: "330283354212",
    appId: "1:330283354212:web:e8516915cdf03d1a717771"
  });

  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log('📱 [firebase-messaging-sw.js] Message reçu en arrière-plan : ', payload);
    
    const notificationTitle = payload.notification?.title || 'Notification Pilates';
    const notificationOptions = {
      body: payload.notification?.body || 'Vous avez reçu une notification',
      icon: '/favicon.ico',
      badge: '/favicon.ico'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
  });

  console.log('✅ Service Worker Firebase initialisé');
} catch (error) {
  console.error('❌ Erreur Service Worker Firebase:', error);
}