resource "google_pubsub_topic" "queue" {
  provider=google
  name = "vllm-${var.purpose}-queue-${var.accelerator_type}"
}

resource "google_pubsub_subscription" "agent_subscription" {
  provider=google
  name  = "${google_pubsub_topic.queue.name}-agent"
  topic = google_pubsub_topic.queue.id  
  ack_deadline_seconds = 600 # 10 minutes
  message_retention_duration = "604800s" # 7 days  
}
