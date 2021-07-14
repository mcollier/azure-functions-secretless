using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public static class QueueTrigger1
    {
        [FunctionName("QueueTrigger1")]
        public static void Run([QueueTrigger("%InputQueueName%", Connection = "QueueConnection")] string myQueueItem, ILogger log)
        {
            //, Connection = "QueueConnection"
            log.LogInformation($"C# Queue trigger function processed: {myQueueItem}");
        }
    }
}
