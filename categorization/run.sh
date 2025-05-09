docker run \
    --name nginx-categorization \
    --network evil \
    --rm \
    -p 80:80 \
    -v ./site/:/usr/share/nginx/html nginx
echo "[+] Categorization server started. Remember to enable configs in haproxy.cfg"
