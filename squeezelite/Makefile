build-image:
	docker build . -f Dockerfile -t squeezelite:latest

push-image:
	docker push squeezelite:latest

run-image:
	docker run -it -e PULSE_SERVER=host.docker.internal --mount type=bind,source=/Users/pansa/.config/pulse,target=/home/pulseaudio/.config/pulse --entrypoint /tmp/squeezelite-linux --rm squeezelite:latest -o null -n ps3

run-local:
	./squeezelite-osx -s 192.168.0.13 -n pilite2

test-pulse:
	docker run -it -e PULSE_SERVER=host.docker.internal --mount type=bind,source=/Users/pansa/.config/pulse,target=/home/pulseaudio/.config/pulse --entrypoint speaker-test --rm jess/pulseaudio -c 2 -l 1 -t wav