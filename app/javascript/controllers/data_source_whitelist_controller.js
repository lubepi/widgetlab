import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userCheckbox", "groupCheckbox", "hiddenContainer", "userHint"]
  static values = {
    groupMembers: Object,
  }

  connect() {
    this.refresh()

    this.onGroupsChanged = () => this.refresh()
    this.groupCheckboxTargets.forEach((cb) => cb.addEventListener("change", this.onGroupsChanged))
  }

  disconnect() {
    if (this.onGroupsChanged) {
      this.groupCheckboxTargets.forEach((cb) => cb.removeEventListener("change", this.onGroupsChanged))
      this.onGroupsChanged = null
    }
  }

  refresh() {
    const inherited = this.inheritedFromSelectedGroups()
    const inheritedUserIds = inherited.userIds

    if (this.hasHiddenContainerTarget) this.hiddenContainerTarget.innerHTML = ""

    this.userCheckboxTargets.forEach((cb) => {
      const userId = parseInt(cb.value, 10)
      const inherited = inheritedUserIds.has(userId)

      if (inherited) {
        cb.checked = true
        cb.disabled = true

        if (this.hasHiddenContainerTarget) {
          const hidden = document.createElement("input")
          hidden.type = "hidden"
          hidden.name = cb.name
          hidden.value = cb.value
          this.hiddenContainerTarget.appendChild(hidden)
        }
      } else {
        cb.disabled = false
      }
    })

    this.renderHints(inherited.byUserId)

    this.dispatchChangeForMemberPicker(this.userCheckboxTargets)
  }

  inheritedFromSelectedGroups() {
    const userIds = new Set()
    const byUserId = new Map()
    const map = this.groupMembersValue || {}

    this.groupCheckboxTargets.forEach((cb) => {
      if (!cb.checked) return

      const groupId = parseInt(cb.value, 10)
      const info = map[groupId] || map[String(groupId)]
      if (!info) return

      const groupName = info.name
      const memberIds = info.member_ids || info.memberIds || []

      memberIds.forEach((uid) => {
        const userId = parseInt(uid, 10)
        userIds.add(userId)

        const names = byUserId.get(userId) || []
        if (groupName && !names.includes(groupName)) names.push(groupName)
        byUserId.set(userId, names)
      })
    })

    return { userIds, byUserId }
  }

  renderHints(byUserId) {
    this.userHintTargets.forEach((el) => {
      const userId = parseInt(el.dataset.userId, 10)
      const names = byUserId.get(userId)
      if (!names || names.length === 0) {
        el.textContent = ""
        return
      }

      el.textContent = `Durch Gruppe ${names.join(", ")}`
    })
  }

  dispatchChangeForMemberPicker(checkboxes) {
    // member-picker updates count on change events; trigger one.
    const any = checkboxes[0]
    if (!any) return
    any.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
