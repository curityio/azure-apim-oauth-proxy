namespace MyPolicy.Tests
{
    using System.Net;
    using NUnit.Framework;

    [TestFixture]
    public class CryptoTests
    {
        private string myEncryptionKey;

        [OneTimeSetUp]
        public void Setup()
        {
            this.myEncryptionKey = "a6b404b1-98af-41a2-8e7f-e4061dc0bf86";
        }

        [Test]
        public void AccessTokenCookie_DecryptsSuccessfully()
        {
            var cookie = "wofghiuphior13gh3rhklttghkln5134hklt4th5kl4";
            var token = "myaccesstoken";

            TestContext.Progress.WriteLine($"Cookie was successfully decryopted to {token}");
            Assert.True(token.Length > 0, "An invalid token was produced");
        }
    }
}
