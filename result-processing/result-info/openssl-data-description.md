# Description of OQS-OpenSSL Result Data

A description of the headers for the OQS-OpenSSL data tables and what they mean are as follows:

1. **Connections in User Time:** This is the number of successful TLS handshakes that were established during the user/CPU time. This gives you a raw number of handshakes per CPU second, which can be useful for understanding the efficiency of the algorithm.

2. **Connections per User Second:** This is the rate at which the TLS handshakes were made per CPU second. This can be useful for understanding the speed of the algorithm under optimal conditions (where it's the only thing the CPU is working on).

3. **Real Time:** This is the wall clock time or elapsed time that includes time spent waiting for I/O or other processes. If this number is significantly higher than the User Time, it could indicate potential system-level issues.

4. **Connections in Real Time:** This number tells you how many handshakes were established in real-world time. This can be useful for understanding the performance of the algorithm in a real-world scenario, where the server may have to handle multiple tasks concurrently.

5. **Connections per User Second (With Session ID Reuse):** The rate of handshakes per CPU second with session ID reuse. This tells you how effectively the algorithm leverages session resumption to speed up the handshake.

6. **Connections in Real Time (With Session ID Reuse):** The number of handshakes in real-world time with session ID reuse. This gives you an understanding of the algorithm's performance in a real-world scenario with session resumption.