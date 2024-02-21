using System;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;

namespace SeleniumTest
{
    [TestFixture]
    class Program
    {
        IWebDriver driver = null;
        
   
        [SetUp]
        public void Setup()
        {
            // Set up Chrome options for headless mode
            var chromeOptions = new ChromeOptions();
            chromeOptions.AddArgument("--headless");

            // Initialize ChromeDriver with options
            driver = new ChromeDriver(chromeOptions);

        }



        [Test]
        public void TestCase1()
        {
            driver.Navigate().GoToUrl("https://www.example.com");
            Assert.AreEqual("Example Domain", driver.Title);
        }

        
        [TearDown]
        public void TearDown()
        {
            // Close the browser
           
            driver.Quit();
        }
               
         
    }


}
