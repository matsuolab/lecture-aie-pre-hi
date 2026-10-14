# अभ्यासों के लिए फ़ोल्डर


## Linux प्रदर्शन
नीचे दी गई फ़ाइल संरचना और अनुमतियाँ तैयार करनी हैं.
अनुमतियाँ `ls -la` में दिखने वाले प्रतीकात्मक रूप में लिखी गई हैं (उदाहरण: `-rw-------`).

```फ़ाइल-संरचना
lecture/                                        drwxr-xr-x
├── README.md                                   -rw-r--r--
├── docker-compose.yml                          -rw-r--r--
├── backend/                                     drwxr-xr-x
│   ├── Dockerfile                              -rw-r--r--
│   ├── main.py                                 -rw-r--r--
|   ├── .env                                    -rw-------  ← chmod 600 (गोपनीय जानकारी के कारण केवल मालिक के लिए)
|   ├── .env.example                            -rw-r--r--  ← साझा करने के लिए टेम्पलेट
│   ├── requirements.txt                        -rw-r--r--
└── frontend/                                    drwxr-xr-x
    ├── Dockerfile                              -rw-r--r--
    ├── index.html                              -rw-r--r--
    ├── package-lock.json                       -rw-r--r--
    ├── package.json                            -rw-r--r--
    ├── tsconfig.json                           -rw-r--r--
    ├── vite.config.ts                          -rw-r--r--
    └── src/                                     drwxr-xr-x
        ├── App.tsx                             -rw-r--r--
        └── main.tsx                            -rw-r--r--
```


## Docker प्रदर्शन
Docker compose से विकास सर्वर शुरू कर सकते हैं.
```
cp backend/.env.example backend/.env && chmod 600 backend/.env   # केवल पहली बार
docker compose up -d --build
```

### भेजने पर त्रुटि 504 दिखे: "संचार विफल रहा".
Codespace में पुरानी फ़ायरवॉल प्रणाली (iptables-legacy) कभी-कभी कंटेनरों के बीच के संचार को रोक देती है.
Compose के नेटवर्क (`br-` से शुरू होने वाले नाम) के बीच संचार की अनुमति देने के लिए Codespace शुरू होने के बाद एक बार यह कमांड चलाएँ.
```
sudo iptables-legacy -I FORWARD 1 -i br-+ -o br-+ -j ACCEPT
```
- Codespace दोबारा शुरू करने पर यह सेटिंग हट जाती है (दोबारा शुरू करने के बाद कमांड फिर चलाएँ).
- सेटिंग हटाने के लिए: `sudo iptables-legacy -D FORWARD -i br-+ -o br-+ -j ACCEPT`

विकास सर्वर इस पते पर उपलब्ध है.
http://localhost:8080/