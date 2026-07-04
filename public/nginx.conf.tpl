server {
    listen 80 default_server;
    server_name _;

    root /var/www/main;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}

# Blog domain
# server {
#     listen 80;
#     server_name blog.afzalex.com;

#     root /var/www/blog;
#     index index.html;

#     location / {
#         try_files $uri $uri/ =404;
#     }

#     location /_astro/ {
#         expires 1y;
#         add_header Cache-Control "public, immutable";
#         try_files $uri =404;
#     }
# }