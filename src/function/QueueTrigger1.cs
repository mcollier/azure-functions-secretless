using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public static class QueueTrigger1
    {
        [FunctionName("QueueTrigger1")]
        public static void Run([QueueTrigger("%QueueName%")] string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# Queue trigger function processed: {myQueueItem}");
        }
    }
}
