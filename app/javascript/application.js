// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import LiveFilterController from "./controllers/live_filter_controller"
const application = Application.start()
application.register("live-filter", LiveFilterController)
import "/mdb/js/mdb.umd.min.js"
