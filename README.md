# Protohackers

This is a copy of the [Protohackers challenges](https://protohackers.com) as demonstrated by Andrea Leopardi on their [YouTube channel](https://www.youtube.com/playlist?list=PLd7I3U4fDsULTLqbRAkWzA002-IzMe8fl).

Run the TCP servers with `mix run --no-halt`

To test a server, you can make a call using netcat, for example `echo foo | nc localhost 5001`

## 0 Smoketest

[Original challenge](https://protohackers.com/problem/0)

[Video implementation](https://www.youtube.com/watch?v=owz50_NYIZ8)

This is implemented in the file `echo_server.ex`.

Notes from the video:
- It's recommended to always use a struct to hold GenServer state.
- A listen socket waits for a TCP connection. Upon accepting a connection, it creates a peer socket which represents the 1:1 connection between the server and client.
- A listen socket can accept many connections, but a peer socket is always 1:1.
- Ensure you set a limit on the client data received to prevent a client from steaming an unlimited amount of data and causing the BEAM to run out of memory.



