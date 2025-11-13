// server
import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { Server } from "socket.io";
import { Server as HttpServer } from "http";

// In-memory room store
const rooms: Array<{
	id: string;
	users: Array<{ username: string; role: string }>; // role: 'host' or 'viewer'
	current_video_url: string;
	playlist: Array<{ title: string; url: string }>;
	current_time?: number; // Current playback time in seconds
	is_playing?: boolean; // Current playback state
}> = [];

const app = new Hono();
app.get("/api/health", (c) => {
	return c.json({ status: "ok" });
});

const server = serve(
	{
		fetch: app.fetch,
		port: 3000,
	},
	(info) => {
		console.log(`Server is running: http://${info.address}:${info.port}`);
	}
);

const io = new Server(server as HttpServer, {
	path: "/ws",
	serveClient: false,
});

io.on("error", (err) => {
	console.log(err);
});

io.on("connection", (socket) => {
	socket.on("create-room", ({ user, current_video_url, playlist }) => {
		const id = Math.random().toString(36).substring(2, 10).toUpperCase();
		const room = {
			id,
			users: user ? [{ username: user, role: "host" }] : [],
			current_video_url: current_video_url || "",
			playlist: Array.isArray(playlist) ? playlist : [],
			current_time: 0,
			is_playing: false,
		};
		rooms.push(room);
		if (user) {
			socket.join(id);
		}
		socket.emit("room-created", { room });
	});

	socket.on("join-room", ({ roomId, user }) => {
		socket.join(roomId);
		const room = rooms.find((r) => r.id === roomId);
		if (room && user) {
			const existingUser = room.users.find((u) => u.username === user);
			if (!existingUser) {
				room.users.push({ username: user, role: "viewer" });
				socket.to(roomId).emit("user-joined", { user, users: room.users });

				// Send sync-playback event to the new user with current playback state
				if (room.current_time !== undefined) {
					socket.emit("sync-playback", {
						currentTime: room.current_time,
						isPlaying: room.is_playing || false,
						timestamp: Date.now(),
					});
				}
			}
		}
		socket.emit("room-data", room);
	});

	// Handle chat messages
	socket.on("chat-message", ({ roomId, message }) => {
		// Broadcast to all users in the room including sender
		socket.broadcast.to(roomId).emit("chat-message", message);
	});

	// Handle playback sync from host
	socket.on("sync-playback", ({ roomId, currentTime, isPlaying }) => {
		const room = rooms.find((r) => r.id === roomId);
		if (room) {
			// Update room state
			room.current_time = currentTime;
			room.is_playing = isPlaying;

			// Broadcast to all other users in the room
			socket.to(roomId).emit("sync-playback", {
				currentTime,
				isPlaying,
				timestamp: Date.now(),
			});
		}
	});

	// Handle playback control events (play, pause, seek)
	socket.on("playback-control", ({ roomId, action, currentTime }) => {
		const room = rooms.find((r) => r.id === roomId);
		if (room) {
			if (action === "play") {
				room.is_playing = true;
				room.current_time = currentTime;
			} else if (action === "pause") {
				room.is_playing = false;
				room.current_time = currentTime;
			} else if (action === "seek") {
				room.current_time = currentTime;
			}

			// Broadcast to all other users in the room
			socket.to(roomId).emit("playback-control", {
				action,
				currentTime,
				timestamp: Date.now(),
			});
		}
	});
});
