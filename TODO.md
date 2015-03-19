# TODO

0. Audit existing code.
    * Add assertions that actions are only invoked if the actor is in
      the right state. E.g., `request_vote!` should raise an exception
      unless we're a follower. Likewise, `send_heartbeats!` should
      raise if we're not master.
    * We can probably improve `set_transition` for this.
0. Add a test where two followers timeout simultaneously. Test split
   elections. Randomize start election timer to prevent repeated split
   elections.
0. Symbolize event names.
0. Remove `Message#time_sent`/`Message#time_received`, which aren't
   necessary for Raft.
0. Extract timer logic out to a module that can be optionally mixed
   into `Actor`. Maybe cause setting/expiry of timers to be a post
   condition of state changes?
0. Change `Actor#start_listening` and `Actor#send_message` to handle
   broken TCP sockets. Should these be done asynchronously? This will
   eliminate the race condition in `raft.rb` where a server starts but
   no one is listening.
0. Can timers be done without using 1 thread per set timer?
