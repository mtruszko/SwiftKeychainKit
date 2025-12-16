import SwiftUI

struct SystemKeychainView: View {
    @State private var vm = SystemKeychainViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("System Keychain Demo")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Secret Value")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    TextField("Enter secret to store", text: $vm.secretText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                HStack(spacing: 12) {
                    Button { Task { await vm.save() } } label: {
                        LoadingButtonLabel(
                            isLoading: vm.isBusy,
                            title: "Save",
                            systemImage: "square.and.arrow.down",
                            progressTint: .white
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.secretText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isBusy)

                    Button { Task { await vm.load() } } label: {
                        LoadingButtonLabel(
                            isLoading: vm.isBusy,
                            title: "Load",
                            systemImage: "square.and.arrow.up",
                            progressTint: .white
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isBusy)

                    Button(role: .destructive) { Task { await vm.delete() } } label: {
                        LoadingButtonLabel(
                            isLoading: vm.isBusy,
                            title: "Delete",
                            systemImage: "trash",
                            progressTint: .red
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.isBusy)
                }

                if let retrieved = vm.retrievedSecret {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Retrieved Secret")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(retrieved)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)

                            Spacer()

                            Button { vm.copyToClipboard(retrieved) } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                if let toast = vm.toast {
                    ToastBanner(toast: toast)
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Keychain")
        }
    }
}

#Preview {
    SystemKeychainView()
}
