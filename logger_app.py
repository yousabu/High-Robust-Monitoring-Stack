from confluent_kafka import Producer
import logging
import time

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

# Set up Kafka producer
conf = {'bootstrap.servers': 'localhost:9092'}
producer = Producer(conf)

def delivery_report(err, msg):
    if err is not None:
        logging.error('Message delivery failed: {}'.format(err))
    else:
        logging.info('Message delivered to {} [{}]'.format(msg.topic(), msg.partition()))

def send_log_to_kafka(message):
    try:
        producer.produce('logs', value=message.encode('utf-8'), callback=delivery_report)
        producer.poll(1)  # Wait up to 1 second for events
        logging.info("Sent log: %s", message)
    except Exception as e:
        logging.error("Failed to send log to Kafka: %s", str(e))

if __name__ == '__main__':
    try:
        while True:
            log_message = "This is a demo log message from youssef"
            send_log_to_kafka(log_message)
            time.sleep(5)  # Send a log every 5 seconds
    except KeyboardInterrupt:
        logging.info("Shutting down gracefully...")
    finally:
        producer.flush()
        logging.info("Kafka Producer closed.")

