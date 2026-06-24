using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
using AXSecurity;


public class AXSecurityDemoBehaviourScript : MonoBehaviour
{

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }


    private string log = "'";


    void OnGUI()
    {
        var margin = 30;
        var width = Screen.width - 2 * margin;
        var buttonHeight = 80;
        var rowHeight = margin + buttonHeight;
        var marginToTop = 200;
        if (GUI.Button(new Rect(margin, marginToTop, width, buttonHeight), "初始化"))
        {
            try
            {
                var config = new Config
                {
                    AccessKeyID = "<YOUR_ACCESS_KEY_ID>",
                    AccessKeySecret = "<YOUR_ACCESS_KEY_SECRET>",
                    EdgeNodes = new string[] { "<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>" },
                    Dns = new DnsConfig
                    {
                        EdgeDohResolveDomains = new string[] { "<YOUR_DOMAIN>" }
                    }
                };
                var res = AXService.GetInsance().Initialize(config);
                Log(res == 0 ? "初始化成功!" : "初始化失败!");
            }
            catch (Exception e)
            {
                Log(e.Message);
            }
        }
        marginToTop += rowHeight;
        if (GUI.Button(new Rect(margin, marginToTop, width, buttonHeight), "获取代理配置"))
        {
            try
            {
                var res = AXService.GetInsance().GetLocalTCPProxy("http://example.com/");
                Log(string.Format("获取代理配置:{0}", res));
            }
            catch (Exception e)
            {
                Log(e.Message);
            }
        }
        marginToTop += rowHeight;

        if (GUI.Button(new Rect(margin, marginToTop, width, buttonHeight), "请求"))
        {
            StartCoroutine(Request());
        }
        marginToTop += rowHeight;
        GUI.Label(new Rect(margin, marginToTop, width, Screen.height - marginToTop - margin), log);
    }



    /// <summary>
    /// 请求
    /// </summary>
    /// <returns></returns>
    IEnumerator Request()
    {
        var url = "https://example.com/";
        UnityWebRequest request;
#if PLATFORM_ANDROID || PLATFORM_IOS
        var config = AXService.GetInsance().GetLocalTCPProxy(url);
        if (config == null)
        {
            Log("获取本地代理失败!");
            yield return null;
        }
        request = UnityWebRequest.Get(string.Format("https://{0}:{1}",config.IP,config.Port));
        request.SetRequestHeader("Host", "example.com");
#else
        request = UnityWebRequest.Get(url);
#endif
        request.certificateHandler = new MyCertificateHandler();
        yield return request.SendWebRequest();
        if (request.result != UnityWebRequest.Result.Success)
        {
            Log(string.Format("请求错误:{0}", request.error));
        }
        else
        {
            Log(string.Format("请求结果:{0}", request.downloadHandler.text));
        }
    }


    /// <summary>
    /// 打入日志
    /// </summary>
    /// <param name="msg"></param>
    void Log(string msg)
    {
        log = msg;
    }


    class MyCertificateHandler : CertificateHandler
    {

        protected override bool ValidateCertificate(byte[] certificateData)
        {
            return true;
        }
    }
}
