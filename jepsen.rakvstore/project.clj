(defproject jepsen.rakvstore "0.1.0-SNAPSHOT"
  :description "Jepsen for raft-based key/value store"
  :url "https://github.com/rabbitmq/ra-kv-store/tree/master/jepsen.rakvstore"
  :license {:name "Apache 2.0 License"
            :url "http://www.apache.org/licenses/LICENSE-2.0.html"}
  :main jepsen.rakvstore
  :dependencies [[org.clojure/clojure "1.9.0"]
                 [jepsen "0.1.8"]])