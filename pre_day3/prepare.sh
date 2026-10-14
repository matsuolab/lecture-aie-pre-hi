#!/bin/sh

# यह pre-Day3 (Docker अभ्यास वाले भाग) की तैयारी का प्रोग्राम है.
# सत्र से पहले इसे एक बार चला लें ताकि सत्र के दौरान प्रतीक्षा न करनी पड़े.
# यह रिपॉज़िटरी में pre_day3/prepare.sh पर रखा है; इसे चलाने के लिए
#   chmod +x pre_day3/prepare.sh
#   ./pre_day3/prepare.sh
# केवल ये दो कमांड हैं (pre-Day2 में सीखी गई क्रियाओं जैसी).

# बीच में कोई त्रुटि आने पर उसी समय रुक जाएँ (-e).
# ऐसे मान का उपयोग करने पर भी रुक जाएँ जो अभी निर्धारित नहीं है (-u).
set -eu

# [1] डाउनलोड किए जाने वाले Docker इमेज और AI मॉडल के संस्करण वेरिएबल में रखें.
#     इस भाग को विद्यार्थियों को बदलना नहीं है.
IMAGE='ghcr.io/ggml-org/llama.cpp:server-v0.5.0'
MODEL_DIR='/workspaces/models'
MODEL_FILE='gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_URL='https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/0314792d7f1f7e229411f620751375812bb9faf2/gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_SHA256='b52f438017efaec5debf1c0d8be690571e212a07c312f1102bbce927258cfc32'
LLM_CHAT_DIR='/workspaces/llm-chat'
# खाली जगह का अनुमान: डाउनलोड लगभग 3.5GB है. थोड़ी अतिरिक्त जगह के साथ 4GB (4×1024×1024 KB) को आधार मानते हैं.
REQUIRED_FREE_KB=4194304

# [2] जाँचें कि Docker सर्वर से जुड़ सकते हैं या नहीं.
#     न जुड़ पाने पर यहीं रुकें और अगला कदम बताएँ.
check_docker() {
  if ! docker version >/dev/null 2>&1; then
    printf '%s\n' 'त्रुटि: Docker उपलब्ध नहीं है.' >&2
    printf '%s\n' 'इस Codespace में Docker अभी पूरी तरह शुरू नहीं हुआ है, या इस परिवेश में Docker उपलब्ध नहीं है.' >&2
    printf '%s\n' 'कुछ दर्जन सेकंड प्रतीक्षा करें, फिर ./pre_day3/prepare.sh दोबारा चलाएँ.' >&2
    exit 1
  fi
}

# [3] /workspaces में खाली जगह जाँचें.
#     जगह कम हो तो यहीं रुकें और अगला कदम बताएँ.
check_disk_space() {
  free_kb=$(df -Pk "$MODEL_DIR_PARENT" | awk 'NR==2 {print $4}')
  if [ "$free_kb" -lt "$REQUIRED_FREE_KB" ]; then
    printf '%s\n' 'त्रुटि: /workspaces में पर्याप्त खाली जगह नहीं है.' >&2
    printf '%s\n' 'कम से कम लगभग 4GB खाली जगह चाहिए (Docker इमेज लगभग 308MB, AI मॉडल लगभग 3.2GB).' >&2
    printf '%s\n' 'इस्तेमाल न हो रहा Codespace हटाएँ या अनावश्यक फ़ाइलें हटाएँ,' >&2
    printf '%s\n' 'फिर ./pre_day3/prepare.sh दोबारा चलाएँ.' >&2
    exit 1
  fi
}

# [4] llama.cpp का Docker इमेज डाउनलोड करें. पहले से डाउनलोड है तो दोबारा न करें.
pull_image() {
  if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    printf '%s\n' "Docker इमेज पहले से डाउनलोड है ($IMAGE). डाउनलोड छोड़ रहे हैं."
    return 0
  fi
  printf '%s\n' "Docker इमेज डाउनलोड कर रहे हैं ($IMAGE). इसमें कुछ मिनट लग सकते हैं."
  if ! docker pull "$IMAGE"; then
    printf '%s\n' 'त्रुटि: Docker इमेज डाउनलोड नहीं हो सकी.' >&2
    printf '%s\n' 'नेटवर्क की स्थिति जाँचें और ./pre_day3/prepare.sh दोबारा चलाएँ.' >&2
    exit 1
  fi
}

# [5] जाँचें कि फ़ाइल का SHA-256 अपेक्षित मान से मेल खाता है. मेल खाए तो 0, अन्यथा 1 लौटाएँ.
matches_sha256() {
  target_file="$1"
  [ -f "$target_file" ] || return 1
  actual=$(sha256sum "$target_file" | awk '{print $1}')
  [ "$actual" = "$MODEL_SHA256" ]
}

# [6] AI मॉडल की फ़ाइल डाउनलोड करें.
#     सत्यापित फ़ाइल को दोबारा डाउनलोड न करें; अधूरी फ़ाइल हटाकर दोबारा डाउनलोड करें.
fetch_model() {
  mkdir -p "$MODEL_DIR"
  model_path="$MODEL_DIR/$MODEL_FILE"
  tmp_path="$model_path.download"

  if matches_sha256 "$model_path"; then
    printf '%s\n' "AI मॉडल पहले से डाउनलोड है और उसकी सामग्री भी सत्यापित है ($model_path). डाउनलोड छोड़ रहे हैं."
    return 0
  fi

  # पिछली बार डाउनलोड अधूरा रहने से कोई फ़ाइल बची हो तो हटाएँ.
  rm -f "$tmp_path"

  printf '%s\n' 'AI मॉडल डाउनलोड कर रहे हैं. इसमें लगभग 1 मिनट लग सकता है.'
  if ! curl --fail --silent --show-error --location --output "$tmp_path" "$MODEL_URL"; then
    rm -f "$tmp_path"
    printf '%s\n' 'त्रुटि: AI मॉडल डाउनलोड नहीं हो सका.' >&2
    printf '%s\n' 'नेटवर्क की स्थिति जाँचें और ./pre_day3/prepare.sh दोबारा चलाएँ.' >&2
    exit 1
  fi

  if ! matches_sha256 "$tmp_path"; then
    rm -f "$tmp_path"
    printf '%s\n' 'त्रुटि: डाउनलोड किए गए AI मॉडल की सामग्री सही नहीं है (SHA-256 मेल नहीं खाता).' >&2
    printf '%s\n' 'संभव है कि डाउनलोड के बीच में कनेक्शन टूट गया हो. ./pre_day3/prepare.sh दोबारा चलाएँ.' >&2
    exit 1
  fi

  mv "$tmp_path" "$model_path"
  printf '%s\n' 'AI मॉडल डाउनलोड हो गया है और उसकी सामग्री की जाँच पूरी है.'
}

# [7] AI के लिए Dockerfile को /workspaces/llm-chat/Dockerfile पर रखें.
#     उसकी सामग्री इसी प्रोग्राम में रखी है (वितरण पेज के Dockerfile जैसी सामग्री).
place_llm_chat_dockerfile() {
  mkdir -p "$LLM_CHAT_DIR"
  cat > "$LLM_CHAT_DIR/Dockerfile" <<'DOCKERFILE'
# [1] आधार (base image): llama.cpp सर्वर वाला Docker इमेज.
#     संस्करण (server-v0.5.0) निश्चित रखें. latest उपयोग करने पर हर बार फिर से बनाते समय सामग्री बदल सकती है.
FROM ghcr.io/ggml-org/llama.cpp:server-v0.5.0

# [2] सेटिंग (environment variable): लोड किए जाने वाले AI मॉडल का पथ.
#     AI मॉडल की फ़ाइल इमेज में न रखें; docker run के -v (bind mount) से बाहर से /models में उपलब्ध कराएँ.
ENV LLAMA_ARG_MODEL=/models/gemma-4-E2B-it-UD-Q4_K_XL.gguf

# [3] सेटिंग: अनुरोध स्वीकार करने का पोर्ट (port). कंटेनर के बाहर से जुड़ने के लिए 0.0.0.0 के पोर्ट 8080 पर सुनें.
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080

# [4] सेटिंग: सोचने की प्रक्रिया (reasoning) बंद करें. बातचीत याद रखने की सीमा (ctx-size).
#     एक उत्तर की अधिकतम लंबाई (n-predict).
ENV LLAMA_ARG_REASONING=off
ENV LLAMA_ARG_CTX_SIZE=4096
ENV LLAMA_ARG_N_PREDICT=256

# [5] सेटिंग: AI को शुरुआती निर्देश (system prompt). इसे बदलकर docker build फिर चलाने पर
#     AI के उत्तर देने का तरीका बदलता है. इस पंक्ति में केवल "" के अंदर के वाक्य बदलना पर्याप्त है.
#     उद्धरण चिह्नों का क्रम न बिगाड़ें (बाहर ', अंदर ").
ENV LLAMA_ARG_UI_CONFIG='{"systemMessage":"आप एक मददगार सहायक हैं. संक्षेप में उत्तर दें."}'
DOCKERFILE
  printf '%s\n' "$LLM_CHAT_DIR/Dockerfile रख दी गई है."
}

# यहाँ से चलाने का क्रम शुरू होता है ([2] से [7] तक के फ़ंक्शन इसी क्रम में बुलाए जाते हैं).
MODEL_DIR_PARENT=$(dirname "$MODEL_DIR")
check_docker
check_disk_space
pull_image
fetch_model
place_llm_chat_dockerfile

printf '%s\n' 'तैयारी पूरी हो गई है'
