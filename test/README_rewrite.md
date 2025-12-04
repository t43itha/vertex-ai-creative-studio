# GenMedia Creative Studio | Vertex AI

> ###### _This is not an officially supported Google product. This project is not eligible for the [Google Open Source Software Vulnerability Rewards Program](https://bughunters.google.com/open-source-security). This project is intended for demonstration purposes only. It is not intended for use in a production environment._

![GenMedia Creative Studio v.next](https://github.com/user-attachments/assets/da5ad223-aa6e-413c-b36e-5d63e5d5b758)

![GenMedia Creative Studio v.next](https://github.com/user-attachments/assets/61977f3c-dbb6-4002-b8c0-77d57aa03cce)

# Table of Contents
- [GenMedia Creative Studio](#genmedia-creative-studio)
- [Quick Start (Local Development)](#quick-start-local-development)
- [Deploying to Google Cloud](#deploying-to-google-cloud)
  - [Prerequisites & Tools](#prerequisites--tools)
  - [Option 1: Interactive Setup (Recommended)](#option-1-interactive-setup-recommended)
  - [Option 2: Manual Deployment (Cloud Run Domain)](#option-2-manual-deployment-cloud-run-domain)
  - [Option 3: Custom Domain (Advanced)](#option-3-custom-domain-advanced)
- [Experiments](#experiments)
- [Solution Design](#solution-design)
- [Contributing & License](#contributing--license)

# GenMedia Creative Studio

> **Browser Compatibility:** For the best experience, we recommend using Google Chrome.

GenMedia Creative Studio is a web application showcasing Google Cloud's generative media capabilities—Veo, Lyria, Chirp, Gemini 2.5 Flash Image Generation, and Gemini TTS—along with custom workflows for creative exploration.

**Current Features:**
*   **Image:** Gemini Image Generation, Imagen 4, Imagen 3, Virtual Try-On
*   **Video:** Veo 3.1, Veo 3, Veo 2
*   **Music & Speech:** Lyria, Chirp 3 HD, Gemini TTS
*   **Workflows:** Character Consistency, Shop the Look, Moodboards, Interior Design

Built with [Mesop](https://mesop-dev.github.io/mesop/) and the [Studio Scaffold](https://github.com/ghchinoy/studio-scaffold).

---

# Quick Start (Local Development)

Want to run the app on your machine to test changes or explore the code?

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/GoogleCloudPlatform/vertex-ai-creative-studio.git
    cd vertex-ai-creative-studio
    ```

2.  **Install dependencies:**
    We use `uv` for fast package management.
    ```bash
    # Install uv if you don't have it
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Sync dependencies
    uv sync
    ```

3.  **Configure Environment:**
    Create a `.env` file from the template.
    ```bash
    cp dotenv.template .env
    ```
    Edit `.env` and set your `PROJECT_ID`. You can leave most other values as defaults.
    > *See [Environment Variables Explainer](./environment_variables.md) for advanced config.*

4.  **Run the App:**
    ```bash
    uv run main.py
    ```
    Open your browser to `http://localhost:8080`.

---

# Deploying to Google Cloud

We use **Terraform** to provision infrastructure (Cloud Run, Firestore, Storage, Load Balancers) and **Cloud Build** to deploy the application code.

## Prerequisites & Tools

Before you begin, ensure you have the following installed:

*   [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/docs/install)
*   [Terraform](https://developer.hashicorp.com/terraform/install) (v1.0+)
*   [jq](https://jqlang.github.io/jq/download/) (Optional, useful for JSON output)

You also need a **Google Cloud Project** with billing enabled.

## Option 1: Interactive Setup (Recommended)

We provide a helper script to check your environment and generate the necessary configuration files.

1.  **Run the setup script:**
    ```bash
    ./infra/setup.sh
    ```
    This script will:
    *   Verify you have the required tools.
    *   Ask for your Project ID and desired Region.
    *   Generate the `terraform.tfvars` file for you.

2.  **Deploy Infrastructure:**
    ```bash
    cd infra
    terraform init
    terraform apply
    ```

3.  **Deploy Application:**
    ```bash
    # From the root of the repository
    ./build.sh
    ```

## Option 2: Manual Deployment (Cloud Run Domain)

Use this method if you want to manually configure Terraform and use the default `*.run.app` URL. This is the simplest manual path.

1.  **Set Environment Variables:**
    ```bash
    export PROJECT_ID=$(gcloud config get project)
    export INITIAL_USER=admin@example.com
    ```

2.  **Configure Terraform:**
    Create a `terraform.tfvars` file in the root directory:
    ```bash
    cat > terraform.tfvars << EOF
    project_id = "$PROJECT_ID"
    initial_user = "$INITIAL_USER"
    use_lb = false
    EOF
    ```

3.  **Apply Infrastructure:**
    ```bash
    terraform init
    terraform apply
    ```
    *Note the `cloud-run-app-url` output.*

4.  **Build & Deploy Code:**
    ```bash
    ./build.sh
    ```

5.  **Grant Access:**
    Allow your user to access the secured Cloud Run service:
    ```bash
    gcloud beta iap web add-iam-policy-binding \
      --project=$PROJECT_ID \
      --resource-type=cloud-run \
      --service=creative-studio \
      --member=user:$INITIAL_USER \
      --role=roles/iap.httpsResourceAccessor
    ```

## Option 3: Custom Domain (Advanced)

Use this if you need a custom domain (e.g., `studio.example.com`) and can manage DNS records.

1.  **Configure Terraform:**
    ```bash
    cat > terraform.tfvars << EOF
    project_id = "$PROJECT_ID"
    initial_user = "$INITIAL_USER"
    domain = "studio.example.com"
    EOF
    ```

2.  **Apply Infrastructure:**
    ```bash
    terraform init
    terraform apply
    ```

3.  **Update DNS:**
    Create an **A Record** in your DNS provider pointing `studio.example.com` to the Load Balancer IP address output by Terraform.

4.  **Deploy Code:**
    ```bash
    ./build.sh
    ```

---

# Experiments

The [Experimental folder](./experiments/) contains stand-alone apps and cutting-edge demos, including:

*   **Promptlandia:** Advanced prompt engineering tool.
*   **Storycraft:** AI video storyboard generation.
*   **MCP Tools:** Model Context Protocol servers for GenAI agents.

See [Experiments README](./experiments/README.md) for details.

# Solution Design

The architecture uses **Cloud Run** to host the Mesop application, **Firestore** for metadata, and **Cloud Storage** for media assets. Access is secured via **Identity Aware Proxy (IAP)**.

**Cloud Run IAP Flow:**
![Solution Design - Cloud Run IAP](https://github.com/user-attachments/assets/ec2c1e04-6890-4246-b134-9923955c0486)

# Contributing & License

*   **Contributing:** See [CONTRIBUTING.md](CONTRIBUTING.md).
*   **License:** Apache 2.0. See [LICENSE](LICENSE).
