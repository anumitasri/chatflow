import { Application } from "@hotwired/stimulus"
const application = Application.start()
import ChatController from "./chat_controller"
application.register("chat", ChatController)
