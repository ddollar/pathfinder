# pathfinder

Become a MITM proxy for an iPhone in order to grab authentication credentials for the Path API and export your data.

## Installation

    $ git clone https://github.com/ddollar/pathfinder.git
    $ cd pathfinder
    $ npm install
    $ foreman start

Navigate to [http://localhost:5000/](http://localhots:5000/) on your iPhone and click the `CA Certificate` link. This will prompt you to trust this CA on your iPhone. Do so.

On your iPhone, go to `Settings -> Wi-Fi` and click the blue arrow next to your home wifi.

Go down to `HTTP Proxy` and set `Server` to the IP address of your workstation and `Port` to `5000`.

Go to your Path app and hit the Refresh icon.

## License

MIT
