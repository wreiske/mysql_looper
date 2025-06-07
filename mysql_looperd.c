// mysql_looper is a simple tool to execute a query in a loop and measure the execution time.
// created by Will Reiske on 6/15/2023

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>

#ifdef HAVE_MARIADB
  #include <mariadb/mysql.h>
#else
  #include <mysql/mysql.h>
#endif

#define MAX_QUERY_LENGTH 2500

double getElapsedTime(struct timeval startTime, struct timeval endTime) {
    return (double)(endTime.tv_sec - startTime.tv_sec) +
           (double)(endTime.tv_usec - startTime.tv_usec) / 1000000.0;
}

double minTime = 0.0;
double maxTime = 0.0;
double totalTime = 0.0;
int iterations = 0;

void handleSignal(int signal) {
    printf("\n");
    printf("Application closed.\n");
    printf("Minimum Time: %.8f seconds\n", minTime);
    printf("Maximum Time: %.8f seconds\n", maxTime);
    printf("Total Time: %.8f seconds\n", totalTime);
    printf("Average Time: %.8f seconds\n", totalTime / iterations);
    printf("Iterations: %d\n", iterations);
    exit(0);
}

void getCurrentDateTime(char* dateTime) {
    time_t now = time(NULL);
    struct tm* tm = localtime(&now);
    strftime(dateTime, 20, "%Y-%m-%d %H:%M:%S", tm);
}

void runDaemon(int interval, char* host, char* user, char* password, int port, char* query, int loop, int outputJson, int outputCsv, int showOutput, int onlyTotal) {
    int outputCount = 0;

    while (1) {
        MYSQL *conn;
        MYSQL_RES *res;
        MYSQL_ROW row;

        // Initialize the connection
        conn = mysql_init(NULL);
        if (conn == NULL) {
            fprintf(stderr, "Error initializing MySQL connection: %s\n", mysql_error(conn));
            exit(1);
        }

        // Connect to the MySQL server
        struct timeval connectStartTime, connectEndTime;
        gettimeofday(&connectStartTime, NULL);

        if (!mysql_real_connect(conn, host, user, password, NULL, port, NULL, 0)) {
            fprintf(stderr, "Error connecting to MySQL server: %s\n", mysql_error(conn));
            exit(1);
        }

        gettimeofday(&connectEndTime, NULL);
        double connectTime = getElapsedTime(connectStartTime, connectEndTime);

        // Prepare the query if it is not provided
        if (strlen(query) == 0) {
            char defaultQuery[] = "SELECT 1;";
            strcpy(query, defaultQuery);
        }

        // Execute the query in a loop
        struct timeval loopStartTime, loopEndTime;
        gettimeofday(&loopStartTime, NULL);

        for (int i = 0; i < loop; i++) {
            if (mysql_query(conn, query)) {
                fprintf(stderr, "Error executing query: %s\n", mysql_error(conn));
                exit(1);
            }

            // Get the result set
            res = mysql_use_result(conn);

            // Fetch and display the result
            if ((row = mysql_fetch_row(res)) != NULL) {
                if (showOutput) {
                    printf("%s\n", row[0]);
                }
            }

            // Free the result set
            mysql_free_result(res);
        }

        gettimeofday(&loopEndTime, NULL);
        double loopTime = getElapsedTime(loopStartTime, loopEndTime);

        // Close the connection
        struct timeval finishStartTime, finishEndTime;
        gettimeofday(&finishStartTime, NULL);

        mysql_close(conn);

        gettimeofday(&finishEndTime, NULL);
        double finishTime = getElapsedTime(finishStartTime, finishEndTime);

        // total time is the sum of connect, loop and finish time
        double totalTimeCurrent = connectTime + loopTime + finishTime;

        // Update min and max times
        if (outputCount == 0) {
            minTime = totalTimeCurrent;
            maxTime = totalTimeCurrent;
        } else {
            if (totalTimeCurrent < minTime) {
                minTime = totalTimeCurrent;
            }
            if (totalTimeCurrent > maxTime) {
                maxTime = totalTimeCurrent;
            }
        }

        // Update total time and iterations
        totalTime += totalTimeCurrent;
        iterations++;

        // Print the timings

        // get the current hostname
        char hostname[1024];

        if (gethostname(hostname, 1024) != 0) {
            fprintf(stderr, "Error getting hostname\n");
            exit(1);
        }

        char dateTime[20];
        getCurrentDateTime(dateTime);

        if (outputJson) {
            if (onlyTotal){
                printf("{ \"totalTime\": %.8f }", totalTime);
            } else {
                printf("{ \"dateTime\": \"%s\", \"hostname\": \"%s\", \"dbHost\": \"%s\", \"dbUser\": \"%s\", \"dbPort\": %d, \"loop\": %d, \"connectTime\": %.8f, \"loopTime\": %.8f, \"finishTime\": %.8f, \"totalTime\": %.8f }",
                    dateTime, hostname, host, user, port, loop, connectTime, loopTime, finishTime, totalTime);
            }
        } else if (outputCsv) {
            if (onlyTotal){
                printf("%.8f", totalTime);
            } else {
                if (outputCount == 0) {
                    printf("dateTime,query,loop,hostname,dbHost,dbUser,connectTime,loopTime,finishTime,totalTime\n");
                }
                printf("%s,%s,%d,%s,%s,%s,%.8f,%.8f,%.8f,%.8f\n",
                    dateTime, query, loop, hostname, host, user, connectTime, loopTime, finishTime, totalTimeCurrent);
            }
        } else {
            if (onlyTotal){
                printf("%.8f", totalTime);
            } else {
                if (outputCount % 10 == 0) {
                    printf("%-19s | %-10s | %-7s | %-20s | %-10s | %-10s | %-13s | %-11s | %-12s | %-11s\n",
                        "Date/Time", "Query", "Looped", "Hostname", "DB Host", "DB User", "Connect Time", "Loop Time", "Finish Time", "Total Time");
                }
                printf("%-19s | %-10s | %-7d | %-20s | %-10s | %-10s | %-13.8f | %-11.8f | %-12.8f | %-11.8f\n",
                    dateTime, query, loop, hostname, host, user, connectTime, loopTime, finishTime, totalTimeCurrent);
            }
        }

        outputCount++;
        sleep(interval);
    }
}

int main(int argc, char *argv[]) {
    const char *host = "localhost";
    const char *user = NULL;
    const char *password = NULL;
    int outputJson = 0;
    int outputCsv = 0;
    int loop = 2500;
    int showOutput = 0;
    int onlyTotal = 0;
    int port = 3306;
    char query[MAX_QUERY_LENGTH] = "";
    int interval = 1;

    // Check the number of command line arguments
    if (argc < 7) {
        fprintf(stderr, "Missing required arguments\n");
        fprintf(stderr, "Usage: %s -h <host> --port 3306 -u <user> -p <password> -l <loop> -q <query> (--json / --csv / --show-output / --only-total) [--interval <seconds>]\n", argv[0]);
        exit(1);
    }

    // Parse the command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            if (strlen(argv[i + 1]) > 255) {
                fprintf(stderr, "Host name cannot exceed 255 characters\n");
                exit(1);
            }
            host = argv[i + 1];
        } else if (strcmp(argv[i], "-u") == 0) {
            if (strlen(argv[i + 1]) > 255) {
                fprintf(stderr, "User name cannot exceed 255 characters\n");
                exit(1);
            }
            user = argv[i + 1];
        } else if (strcmp(argv[i], "-p") == 0) {
            if (strlen(argv[i + 1]) > 255) {
                fprintf(stderr, "Password cannot exceed 255 characters\n");
                exit(1);
            }
            password = argv[i + 1];
        } else if (strcmp(argv[i], "-l") == 0) {
            if (atoi(argv[i + 1]) < 0) {
                fprintf(stderr, "Loop count cannot be less than 0\n");
                exit(1);
            }
            loop = atoi(argv[i + 1]);
        } else if (strcmp(argv[i], "-q") == 0) {
            if (strlen(argv[i + 1]) > MAX_QUERY_LENGTH) {
                fprintf(stderr, "Query length cannot exceed %d characters\n", MAX_QUERY_LENGTH);
                exit(1);
            }
            strcpy(query, argv[i + 1]);
        } else if (strcmp(argv[i], "--json") == 0) {
            outputJson = 1;
        } else if (strcmp(argv[i], "--csv") == 0) {
            outputCsv = 1;
        } else if (strcmp(argv[i], "--show-output") == 0) {
            showOutput = 1;
        } else if (strcmp(argv[i], "--port") == 0) {
            if (atoi(argv[i + 1]) < 1 || atoi(argv[i + 1]) > 65535) {
                fprintf(stderr, "Port cannot be less than 1 or greater than 65535\n");
                exit(1);
            }
            port = atoi(argv[i + 1]);
        } else if (strcmp(argv[i], "--only-total") == 0) {
            onlyTotal = 1;
        } else if (strcmp(argv[i], "--interval") == 0) {
            if (atoi(argv[i + 1]) < 0) {
                fprintf(stderr, "Interval cannot be less than 0\n");
                exit(1);
            }
            interval = atoi(argv[i + 1]);
        }
    }

    // Check if all required arguments are provided
    if (user == NULL || password == NULL) {
        fprintf(stderr, "Missing required arguments\n");
        exit(1);
    }

    // if host is not defined, let the user know that it is using localhost
    if (strcmp(host, "localhost") == 0) {
        printf("Using localhost. Use -h to define a target host.\n");
    }

    // Register signal handler for Ctrl-C
    signal(SIGINT, handleSignal);

    runDaemon(interval, host, user, password, port, query, loop, outputJson, outputCsv, showOutput, onlyTotal);

    return 0;
}
