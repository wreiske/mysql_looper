// mysql_looper is a simple tool to execute a query in a loop and measure the execution time.
// created by Will Reiske on 6/15/2023

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#ifdef HAVE_MARIADB
  #include <mariadb/mysql.h>
#else
  #include <mysql/mysql.h>
#endif


#include <unistd.h>

#define MAX_QUERY_LENGTH 2500

double getElapsedTime(struct timeval startTime, struct timeval endTime) {
    return (double)(endTime.tv_sec - startTime.tv_sec) +
           (double)(endTime.tv_usec - startTime.tv_usec) / 1000000.0;
}

int main(int argc, char *argv[]) {
    MYSQL *conn;
    MYSQL_RES *res;
    MYSQL_ROW row;
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

    // Check the number of command line arguments
    if (argc < 7) {
        fprintf(stderr, "Missing required arguments\n");
        fprintf(stderr, "Usage: %s -h <host> --port 3306 -u <user> -p <password> -l <loop> -q <query> (--json / --csv / --show-output / --only-total)\n", argv[0]);
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
            if (atoi(argv[i + 1]) < 1) {
                fprintf(stderr, "Loop count cannot be less than 1\n");
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
        strcpy(query, "SELECT 1;");
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
    double totalTime = connectTime + loopTime + finishTime;

    // Print the timings

    // get the current hostname 
    char hostname[1024];

    if (gethostname(hostname, 1024) != 0) {
        fprintf(stderr, "Error getting hostname\n");
        exit(1);
    }

    if (outputJson) {
        if (onlyTotal){
            printf("{\n");
            printf("  \"totalTime\": %.8f\n", totalTime);
            printf("}\n");
            return 0;
        }

        printf("{\n");
        printf("  \"hostname\": \"%s\",\n", hostname);
        printf("  \"dbHost\": \"%s\",\n", host);
        printf("  \"dbUser\": \"%s\",\n", user);
        printf("  \"dbPort\": %d,\n", port);
        printf("  \"loop\": %d,\n", loop);
        printf("  \"connectTime\": %.8f,\n", connectTime);
        printf("  \"loopTime\": %.8f,\n", loopTime);
        printf("  \"finishTime\": %.8f,\n", finishTime);
        printf("  \"totalTime\": %.8f\n", totalTime);
        printf("}\n");
        return 0;
    } 

    if (outputCsv) {
        if (onlyTotal){
            printf("%.8f\n", totalTime);
            return 0;
        }

        printf("hostname,dbHost,dbUser,dbPort,loop,query,connectTime,loopTime,finishTime,totalTime\n");
        printf("%s,%s,%s,%d,%d,%s,%.8f,%.8f,%.8f,%.8f\n", 
               hostname, host, user, port, loop, query, connectTime, loopTime, finishTime, totalTime);
        return 0;
    } 

    if (onlyTotal){
        printf("%.8f\n", totalTime);
        return 0;
    }
    printf("Query: %s\n", query);
    printf("Looped %d times\n", loop);
    printf("Hostname: %s\n", hostname);
    printf("DB Host: %s\n", host);
    printf("DB User: %s\n", user);
    printf("Connect Time: %.8f seconds\n", connectTime);
    printf("Loop Time: %.8f seconds\n", loopTime);
    printf("Finish Time: %.8f seconds\n", finishTime);
    printf("Total Time: %.8f seconds\n", totalTime);

    return 0;
}
