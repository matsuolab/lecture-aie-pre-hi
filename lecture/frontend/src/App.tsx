import { useState } from "react";

// nginx /app/api को backend कंटेनर पर रिवर्स प्रॉक्सी करता है, इसलिए
// frontend उसी ओरिजिन के सापेक्ष पथ पर अनुरोध भेज सकता है जिससे उसे खोला गया है.
// (localhost हार्डकोड करने पर Codespace जैसे किसी दूसरे होस्ट से अनुरोध नहीं पहुँच पाएगा.)
const API_URL = "/app/api";

export function App() {
  const [inputText, setInputText] = useState("");
  const [result, setResult] = useState("");

  const handleSend = async () => {
    if (!inputText) return;

    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ input_text: inputText }),
      });

      if (!response.ok) {
        throw new Error("API में त्रुटि हुई");
      }

      const data = await response.json();
      setResult(`उत्तर: ${data.reply}`);
    } catch (error) {
      console.error(error);
      setResult("संचार विफल रहा.");
    }
  };

  return (
    <>
      <h1>Docker Compose Demo</h1>
      <input
        type="text"
        placeholder="संदेश लिखें"
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
      />
      <button onClick={handleSend}>भेजें</button>
      <p>{result}</p>
    </>
  );
}
