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

        [Test]
        public void TestCase2()
        {
            driver.Navigate().GoToUrl("https://www.example.com");
            IWebElement element = driver.FindElement(By.LinkText("More information..."));
            element.Click();
            Assert.AreEqual("IANA — IANA-managed Reserved Domains", driver.Title);
        }

        [Test]
        public void TestCase3()
        {
            driver.Navigate().GoToUrl("https://www.example.com");
            IWebElement element = driver.FindElement(By.Id("about"));
            element.Click();
            Assert.AreEqual("IANA — IANA-managed Reserved Domains", driver.Title);
        }

        [Test]
        public void TestCase4()
        {
            driver.Navigate().GoToUrl("https://www.example.com");
            IWebElement element = driver.FindElement(By.XPath("//a[contains(text(),'More information...')]"));
            element.Click();
            Assert.AreEqual("IANA — IANA-managed Reserved Domains", driver.Title);
        }

        [Test]
        public void TestCase5()
        {
            driver.Navigate().GoToUrl("https://www.example.com");
            IWebElement element = driver.FindElement(By.CssSelector("a[href*='iana.org']"));
            element.Click();
            Assert.AreEqual("IANA — IANA-managed Reserved Domains", driver.Title);
        }

        [TearDown]
        public void TearDown()
        {
            // Close the browser
           
            driver.Quit();
        }
               
         
    }


}
