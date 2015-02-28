# TODO

Why wasn't there a conflict when we asked two servers to request to be master?! raft.rb line 16 and 17

We should only get elected master once.

Timer! Cancel a timer?
  When someone fails to receive a heartbeat, they want to ask to be master.

Meaningful "raft" responses to messages, e.g. vote for master

