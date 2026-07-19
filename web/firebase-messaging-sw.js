importScripts('https://www.gstatic.com/firebasejs/10.9.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.9.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyCh0wN2xKZ48YOqTiVz49Su1lqU_KQp1T4',
  authDomain: 'practicaseguridad-ce941.firebaseapp.com',
  projectId: 'practicaseguridad-ce941',
  storageBucket: 'practicaseguridad-ce941.firebasestorage.app',
  messagingSenderId: '568401217661',
  appId: '1:568401217661:web:039b9e49ec4762655e8914',
  measurementId: 'G-P2C7WLM831',
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'Notificación';
  const notificationOptions = {
    body: payload.notification?.body || 'Tienes un mensaje nuevo.',
    icon: '/icons/Icon-192.png',
    tag: 'fcm-notification',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
