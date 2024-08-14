import mqtt from "mqtt";
// Ganti dengan nama service EMQX di docker-compose
const brokerUrl = 'mqtt://localhost:1883';
const clientId = 'nodejs_mqtt_client';


// Menghubungkan ke broker EMQX
const client = mqtt.connect(brokerUrl, {
    clientId: clientId,
    clean: true,
    connectTimeout: 4000,
    username: 'developer', // Ganti dengan username yang telah ditambahkan
    password: 'Cyberhack2010', // Ganti dengan password yang telah ditambahkan
    reconnectPeriod: 1000,
});

client.on('connect', () => {
    console.log('Connected to EMQX');

    // Subscribe ke topik
    const topic = 'test/topic';
    client.subscribe(topic, (err) => {
        if (!err) {
            console.log(`Subscribed to ${topic}`);
        }
    });

    client.publish(topic, Buffer.from('Hello MQTT'), { qos: 0, retain: false }, (err) => {
        if (err) {
            console.error('Failed to publish message:', err);
        } else {
            console.log('Message published');
        }
    });
});

client.on('message', (topic, message) => {
    console.log(`Received message: ${message.toString()} from topic: ${topic}`);
});

client.on('error', (err) => {
    console.error('Connection error:', err);
});

client.on('reconnect', () => {
    console.log('Reconnecting...');
});

client.on("disconnect",() => {

})

client.on('close', () => {
    console.log('Connection closed');
});


