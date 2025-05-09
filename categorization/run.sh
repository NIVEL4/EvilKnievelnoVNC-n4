docker run \
    --name nginx-categorization \
    --network evil \
    --rm \
    -v ./site/:/usr/share/nginx/html nginx
echo "[+] Categorization server started. Remember to enable configs in haproxy.cfg"
