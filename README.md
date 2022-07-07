# WordPress for Docker (extends official image)

The official image works well for a simple WordPress installation, however, what happens if you want to deploy WordPress in Docker Swarm and scale it for more than two instances?

This `Dockerfile` has built-in *steroids* to handle scalling and includes:
- Uses PHP-FPM 8.0
- Stores PHP sessions in [memcached](https://memcached.org/)
- Includes [composer `autoload.php` as `mu-plugin`](https://gist.github.com/lightningspirit/73df703f0db1fef14bd30d64ea1e8631)
- Adds Docker Healthchecks
- Includes a copy of [WP-CLI](https://wp-cli.org/)
- Installs WordPress cron to local crontab
- Enables OpCache and APCu
- Installs [S3-Uploads](https://github.com/humanmade/S3-Uploads) plugins to store media in AWS S3

Does it sound awesome? Give it a try!

## Usage
Refer to the `docker-compose.yml` file for a comprehensive example.

## Architectural concept

The main idea was to scale WordPress using two Docker Swarm nodes. We manage to have it with the following architecture:

- One WordPress instance running in each node
- Memcached running in one node
- A AWS S3 bucket to store media
- One [MariaDB Maxscale](https://mariadb.com/kb/en/maxscale/) running in one node
- One master MariaDB running in the first node
- One slave MariaDB running in the second node

