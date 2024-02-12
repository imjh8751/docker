for i in {1..1000}; do docker exec redis-node1 redis-cli -p 6001 -a master SET "key$i" "value$i"; done
