import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "progressBar", "counter", "image"]

  connect() {
    this.currentStep = 0
    this.totalSteps = this.stepTargets.length
    this.showStep(0)
  }

  showStep(index) {
    this.stepTargets.forEach((step, i) => {
      step.style.display = i === index ? "flex" : "none"
    })
    const percent = this.totalSteps > 1 ? Math.round((index / (this.totalSteps - 1)) * 100) : 100
    this.progressBarTarget.style.width = `${percent}%`
    this.counterTarget.textContent = `Question ${index + 1} of ${this.totalSteps}`

    // swap left panel image
    const imageUrl = this.stepTargets[index].dataset.image
    if (imageUrl && this.hasImageTarget) {
      this.imageTarget.style.backgroundImage = `url('${imageUrl}')`
    }
  }

  next() {
    if (this.currentStep < this.totalSteps - 1) {
      this.currentStep++
      this.showStep(this.currentStep)
    }
  }

  previous() {
    if (this.currentStep > 0) {
      this.currentStep--
      this.showStep(this.currentStep)
    }
  }

  selectOption(event) {
    const step = this.stepTargets[this.currentStep]
    step.querySelectorAll(".option-card").forEach(card => {
      card.classList.remove("selected")
    })
    event.currentTarget.classList.add("selected")
  }
}
