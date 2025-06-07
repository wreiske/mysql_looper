# mysql_looper

`mysql_looper` is a simple command-line tool to execute a MySQL query in a loop and measure the execution time.

## Prerequisites

- MySQL C API installed (`libmysqlclient-dev` on ubuntu/debian systems)
- CMake 3.10 or higher


## Usage

```sh
mysql_looper -h <host> --port 3306 -u <user> -p <password> -l <loop> -q <query> (--json / --csv / --show-output / --only-total)
```

### Options

- `-h`: The target database host (e.g., "localhost")
- `--port`: The port of the target database (default: 3306)
- `-u`: The user to connect to the target database (e.g., "root")
- `-p`: The password for the user to connect to the target database (e.g., "mypassword")
- `-l`: The loop count to execute the query (e.g., 1000)
- `-q`: The query to be executed (e.g., "SELECT * FROM users;")
- `--json`: Optional flag to output the result in JSON format
- `--csv`: Optional flag to output the result in CSV format
- `--show-output`: Optional flag to output the row result for each query loop
- `--only-total`: Optional flag to only show the total time taken for all steps
- `--interval`: Optional flag to change the interval the daemon loop runs (only available in mysql_looperd)

## Examples

1. Execute a simple query 1000 times and output the result in human-readable format:

```sh
mysql_looper -h localhost -u root -p mypassword -l 1000 -q "SELECT 1;"
```

2. Execute a complex query 2500 times and output the result in JSON format without row results.

```sh
mysql_looper -h localhost -u root -p mypassword -l 2500 -q "SELECT id FROM users JOIN orders on users.id = orders.user_id;" --json
```

3. Execute a query 5000 times and only show the total time taken for all steps

```sh
mysql_looper -h localhost -u root -p mypassword -l 5000 -q "SELECT id FROM users;" --only-total
```

4. Execute a query 1000 times and output the result in CSV format for easy analysis

```sh
mysql_looper -h localhost -u root -p mypassword -l 1000 -q "SELECT id FROM users;" --csv
```

## Output mysql_looper

`mysql_looper` will print the following information:

```sh
./mysql_2500 -h exampledb.example.com -u root -p removed -l 2500
Query: SELECT 1;
Looped 2500 times
Hostname: examplehost.example.com
DB Host: exampledb.example.com
DB User: root
Connect Time: 0.00188700 seconds
Loop Time: 1.02145300 seconds
Finish Time: 0.00008700 seconds
Total Time: 1.02342700 seconds

./mysql_2500 -h exampledb.example.com -u root -p removed -l 100 --json
{
  "hostname": "examplehost.example.com",
  "dbHost": "exampledb.example.com",
  "dbUser": "root",
  "dbPort": 3306,
  "loop": 100,
  "connectTime": 0.002254,
  "loopTime": 0.058448,
  "finishTime": 0.000188
  "totalTime": 0.060890
}

./mysql_2500 -h exampledb.example.com -u root -p removed -l 100 --csv
hostname,dbHost,dbUser,dbPort,loop,query,connectTime,loopTime,finishTime,totalTime
examplehost.example.com,exampledb.example.com,root,3306,100,SELECT 1;,0.00225400,0.05844800,0.00018800,0.06089000
```


## Output mysql_looperd

```
Date/Time           | Query      | Looped  | Hostname             | DB Host    | DB User    | Connect Time  | Loop Time   | Finish Time  | Total Time
2024-01-04 17:53:13 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00034700    | 0.17644900  | 0.00000600   | 0.17680200
2024-01-04 17:53:14 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00039100    | 0.16209400  | 0.00000600   | 0.16249100
2024-01-04 17:53:14 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00025000    | 0.11095000  | 0.00000600   | 0.11120600
2024-01-04 17:53:14 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00035100    | 0.17214000  | 0.00000600   | 0.17249700
2024-01-04 17:53:14 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00041100    | 0.18554500  | 0.00001000   | 0.18596600
2024-01-04 17:53:14 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00041800    | 0.18845000  | 0.00001000   | 0.18887800
2024-01-04 17:53:14 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00037500    | 0.18287000  | 0.00000700   | 0.18325200
2024-01-04 17:53:15 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00030300    | 0.16948300  | 0.00000800   | 0.16979400
2024-01-04 17:53:15 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00048100    | 0.14839000  | 0.00000700   | 0.14887800
2024-01-04 17:53:15 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00055800    | 0.16901800  | 0.00000600   | 0.16958200
Date/Time           | Query      | Looped  | Hostname             | DB Host    | DB User    | Connect Time  | Loop Time   | Finish Time  | Total Time
2024-01-04 17:53:15 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00058300    | 0.11536300  | 0.00000600   | 0.11595200
2024-01-04 17:53:15 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00030300    | 0.16597900  | 0.00000800   | 0.16629000
2024-01-04 17:53:15 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00041600    | 0.16989900  | 0.00000600   | 0.17032100
2024-01-04 17:53:16 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00063100    | 0.16811600  | 0.00000600   | 0.16875300
2024-01-04 17:53:16 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00035400    | 0.16700300  | 0.00000600   | 0.16736300
2024-01-04 17:53:16 | SELECT 1;  | 2500    | mie-phxdc-bmc-web1   | 10.9.0.11  | wc_phx     | 0.00030500    | 0.18330300  | 0.00000600   | 0.18361400
^C
Application closed.
Minimum Time: 0.11120600 seconds
Maximum Time: 0.21818600 seconds
Total Time: 13.26568400 seconds
Average Time: 0.17454847 seconds
Iterations: 76
```


## Building with CMake

```sh
mkdir build
cd build
cmake ..
make
```
