using System.Buffers.Binary;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.IO.Compression;
using System.Reflection;
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Xml.Linq;

if (args is ["--native-only", var nativeRoot])
{
    VerifyNative(Path.GetFullPath(nativeRoot));
}
else if (args is [var packagePath, var packageRoot])
{
    var root = Path.GetFullPath(packageRoot);
    var frameworkFiles = VerifyNative(root);
    VerifyPackage(Path.GetFullPath(packagePath), root, frameworkFiles);
}
else
{
    Console.Error.WriteLine("Usage: PackageVerifier [--native-only REPO_ROOT | PACKAGE.nupkg REPO_ROOT]");
    return 2;
}

return 0;

static Dictionary<string, FrameworkEntry> VerifyNative(string root)
{
    var nativeRoot = Path.Combine(root, "native/MicrosoftSwiftUIShim");
    var framework = Path.Combine(root, ".build/native/MicrosoftSwiftUIShim.xcframework");
    var lines = File.ReadAllLines(Path.Combine(root, ".build/native/MicrosoftSwiftUIShim.provenance.txt"));
    var sources = ReadHashes(lines, "Source SHA-256:", "XCFramework SHA-256:");
    var sourcePaths = Directory.EnumerateFiles(Path.Combine(nativeRoot, "Sources"), "*.swift", SearchOption.AllDirectories)
        .Select(path => Path.GetRelativePath(nativeRoot, path).Replace('\\', '/'))
        .Append("Package.swift")
        .ToHashSet(StringComparer.Ordinal);
    Require(sources.Keys.ToHashSet(StringComparer.Ordinal).SetEquals(sourcePaths),
        "Native source list differs from the XCFramework build provenance.");
    foreach (var (path, hash) in sources)
        Require(Hash(File.ReadAllBytes(Path.Combine(nativeRoot, path))) == hash,
            $"Native source changed since XCFramework build: {path}");

    var binaries = new[]
    {
        "ios-arm64/MicrosoftSwiftUIShim.framework/MicrosoftSwiftUIShim",
        "ios-arm64_x86_64-simulator/MicrosoftSwiftUIShim.framework/MicrosoftSwiftUIShim",
        "macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/Versions/A/MicrosoftSwiftUIShim",
    };
    var hashes = ReadHashes(lines, "XCFramework SHA-256:", "XCFramework inventory (JSON):");
    Require(hashes.Keys.ToHashSet(StringComparer.Ordinal).SetEquals(binaries.Append("Info.plist")),
        "XCFramework binary list differs from its build provenance.");
    foreach (var (path, hash) in hashes)
    {
        var bytes = File.ReadAllBytes(Path.Combine(framework, path));
        Require(Hash(bytes) == hash, $"Generated XCFramework differs from its build provenance: {path}");
        if (path != "Info.plist")
        {
            Require(bytes.AsSpan().IndexOf("deactivateHost:"u8) >= 0,
                $"Native host-deactivation selector missing from generated framework: {path}");
            Require(bytes.AsSpan().IndexOf("setTransparentDeleteBackdrop:"u8) >= 0,
                $"Native delete-backdrop selector missing from generated framework: {path}");
        }
    }

    var inventoryHeading = Array.IndexOf(lines, "XCFramework inventory (JSON):");
    Require(inventoryHeading == lines.Length - 2, "Build provenance has no complete XCFramework inventory.");
    var inventory = JsonSerializer.Deserialize<FrameworkInventory>(
        lines[inventoryHeading + 1], new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
    Require(inventory is { Version: 1, Entries.Length: > 0 },
        "Build provenance has an invalid XCFramework inventory.");
    var files = new Dictionary<string, FrameworkEntry>(StringComparer.Ordinal);
    CollectFiles(new DirectoryInfo(framework), framework, files);
    var recorded = new HashSet<string>(StringComparer.Ordinal);
    foreach (var item in inventory.Entries)
    {
        Require(item.Path == "" ||
                (!Path.IsPathRooted(item.Path) && !item.Path.Contains('\\') &&
                 item.Path.Split('/').All(part => part.Length > 0 && part is not ("." or ".."))),
            $"Invalid XCFramework inventory path: {item.Path}");
        Require(recorded.Add(item.Path), $"Duplicate XCFramework inventory entry: {item.Path}");
        Require(files.TryGetValue(item.Path, out var actual),
            $"XCFramework inventory is missing an entry: {item.Path}");
        Require(item.Mode is >= 0 and <= 0xfff && item.Kind == actual.Kind &&
                item.Mode == actual.Mode,
            $"Generated XCFramework entry type or mode differs from inventory: {item.Path}");
        if (item.Kind == "file")
        {
            Require(item.Sha256 is { Length: 64 } &&
                    item.Sha256.All(char.IsAsciiHexDigit) &&
                    Hash(actual.Contents) == item.Sha256.ToLowerInvariant() && item.Target is null,
                $"Generated XCFramework file differs from inventory: {item.Path}");
        }
        else if (item.Kind == "symlink")
        {
            Require(item.Target is not null && item.Sha256 is null &&
                    actual.Contents.AsSpan().SequenceEqual(Encoding.UTF8.GetBytes(item.Target)),
                $"Generated XCFramework symlink differs from inventory: {item.Path}");
        }
        else
            Require(item.Kind == "directory" && item.Sha256 is null && item.Target is null,
                $"Invalid XCFramework inventory entry: {item.Path}");
    }
    Require(recorded.SetEquals(files.Keys),
        $"Generated XCFramework has unrecorded entries: {string.Join(", ", files.Keys.Except(recorded))}");
    foreach (var plist in new[]
    {
        "Info.plist",
        "ios-arm64/MicrosoftSwiftUIShim.framework/Info.plist",
        "ios-arm64_x86_64-simulator/MicrosoftSwiftUIShim.framework/Info.plist",
        "macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/Versions/A/Resources/Info.plist",
    })
        Require(files.TryGetValue(plist, out var entry) && entry.Kind == "file",
            $"Missing required XCFramework per-slice Info.plist: {plist}");
    foreach (var (link, target) in new[]
    {
        ("macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/Resources", "Versions/Current/Resources"),
        ("macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/MicrosoftSwiftUIShim", "Versions/Current/MicrosoftSwiftUIShim"),
        ("macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/Versions/Current", "A"),
    })
        Require(files.TryGetValue(link, out var entry) && entry.Kind == "symlink" &&
                Encoding.UTF8.GetString(entry.Contents) == target,
            $"Missing required XCFramework symlink: {link}");
    Console.WriteLine($"Native framework matches {sources.Count} source hashes and {files.Count} inventoried entries; all three binaries contain deactivateHost:.");
    return files;
}

static Dictionary<string, string> ReadHashes(string[] lines, string heading, string? nextHeading)
{
    var start = Array.IndexOf(lines, heading);
    Require(start >= 0, $"Build provenance is missing {heading}");
    var end = nextHeading is null ? lines.Length : Array.IndexOf(lines, nextHeading);
    Require(end > start, $"Build provenance is missing {nextHeading}");
    var result = new Dictionary<string, string>(StringComparer.Ordinal);
    foreach (var line in lines[(start + 1)..end].Where(line => line.Length > 0))
    {
        Require(line.Length > 66 && line[64..66] == "  " &&
                line[..64].All(character => char.IsAsciiHexDigit(character)), $"Invalid provenance hash: {line}");
        var path = line[66..];
        if (path.StartsWith("./", StringComparison.Ordinal))
            path = path[2..];
        Require(!Path.IsPathRooted(path) && !path.Split('/').Contains("..") && result.TryAdd(path, line[..64].ToLowerInvariant()),
            $"Invalid or duplicate provenance path: {path}");
    }
    return result;
}

static void CollectFiles(FileSystemInfo entry, string root, Dictionary<string, FrameworkEntry> files)
{
    var path = Path.GetRelativePath(root, entry.FullName).Replace('\\', '/');
    if (path == ".")
        path = "";
    if (entry.LinkTarget is { } link)
        files.Add(path, new FrameworkEntry("symlink", ReadSymlinkMode(entry.FullName),
            Encoding.UTF8.GetBytes(link)));
    else if (entry is DirectoryInfo directory)
    {
        files.Add(path, new FrameworkEntry("directory", (int)entry.UnixFileMode, []));
        foreach (var child in directory.EnumerateFileSystemInfos())
            CollectFiles(child, root, files);
    }
    else
        files.Add(path, new FrameworkEntry("file", (int)entry.UnixFileMode,
            File.ReadAllBytes(entry.FullName)));
}

static int ReadSymlinkMode(string path)
{
    // FileSystemInfo.UnixFileMode follows links; stat without -L reads the link's own mode.
    var start = new ProcessStartInfo("/usr/bin/stat")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
    };
    start.ArgumentList.Add("-f");
    start.ArgumentList.Add("%Lp");
    start.ArgumentList.Add(path);
    using var process = Process.Start(start) ??
        throw new InvalidDataException($"Cannot inspect XCFramework symlink: {path}");
    var output = process.StandardOutput.ReadToEnd().Trim();
    var error = process.StandardError.ReadToEnd().Trim();
    process.WaitForExit();
    Require(process.ExitCode == 0 && Regex.IsMatch(output, "^[0-7]{3,4}$"),
        $"Cannot read XCFramework symlink mode without following it: {path}: {error}");
    return Convert.ToInt32(output, 8);
}

static void VerifyPackage(string path, string root, Dictionary<string, FrameworkEntry> frameworkFiles)
{
    var project = XDocument.Load(Path.Combine(root, "src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj"));
    var version = project.Descendants("Version").Single().Value;
    var platforms = project.Descendants("TargetFrameworks").Single().Value.Split(';');
    Require(platforms.ToHashSet(StringComparer.Ordinal).SetEquals(["net11.0-ios", "net11.0-macos"]) &&
            platforms.Length == 2, "The binding project must target exactly iOS and macOS.");
    var reference = project.Descendants("NativeReference").Single();
    var referencePath = reference.Attribute("Include")?.Value;
    Require(referencePath == "../../.build/native/MicrosoftSwiftUIShim.xcframework" &&
            Path.GetFullPath(Path.Combine(root, "src/Microsoft.SwiftUI", referencePath)) ==
            Path.Combine(root, ".build/native/MicrosoftSwiftUIShim.xcframework"),
        "The native framework reference path differs from the generated XCFramework.");
    var canonical = Path.Combine(root, "artifacts", $"Microsoft.SwiftUI.{version}.nupkg");
    Require(path == canonical, $"Expected canonical package at {canonical}, got {path}");
    var packageBytes = File.ReadAllBytes(path);
    using var package = new ZipArchive(new MemoryStream(packageBytes), ZipArchiveMode.Read);
    VerifyUnixZip(packageBytes, package, "NuGet");
    foreach (var entry in package.Entries)
        Require(entry.ExternalAttributes == unchecked((int)0x81A40000u),
            $"NuGet ZIP entry is not a regular 0644 file: {entry.FullName}");
    Require(package.Entries.Count(entry => entry.FullName == "Microsoft.SwiftUI.nuspec") == 1,
        "NuGet metadata is missing or duplicated.");
    XNamespace ns = "http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd";
    XElement metadata;
    using (var stream = package.GetEntry("Microsoft.SwiftUI.nuspec")!.Open())
    {
        var document = XDocument.Load(stream);
        Require(document.Root?.Name == ns + "package" &&
                document.Root.Elements().Count() == 1 &&
                document.Root.Element(ns + "metadata") is not null,
            "NuGet metadata has an invalid package root.");
        metadata = document.Root!.Element(ns + "metadata")!;
    }
    Require(metadata.Element(ns + "id")?.Value == "Microsoft.SwiftUI" &&
            metadata.Element(ns + "version")?.Value == version &&
            metadata.Element(ns + "readme")?.Value == "README.md" &&
            metadata.Element(ns + "license") is { Value: "MIT" } license &&
            license.Attribute("type")?.Value == "expression",
        "NuGet metadata differs from the project package ID, version, or documents.");
    var dependencies = metadata.Elements(ns + "dependencies").ToArray();
    Require(dependencies.Length == 1 && !dependencies[0].HasAttributes,
        "NuGet dependency groups do not match the binding platform targets.");
    var groups = dependencies[0].Elements().ToArray();
    Require(groups.Length == platforms.Length &&
            groups.All(group => group.Name == ns + "group" &&
                group.Attributes().Count() == 1 && group.Attribute("targetFramework") is not null) &&
            dependencies[0].Nodes().OfType<XText>().All(text => string.IsNullOrWhiteSpace(text.Value)),
        "NuGet dependency groups do not match the binding platform targets.");
    Require(groups.All(group => !group.HasElements && string.IsNullOrWhiteSpace(group.Value)),
        "NuGet dependency groups must be empty.");
    var expectedEntries = new HashSet<string>(StringComparer.Ordinal)
    {
        "_rels/.rels",
        "Microsoft.SwiftUI.nuspec",
        "LICENSE",
        "README.md",
        "docs/ATTRIBUTION.md",
        "[Content_Types].xml",
        "package/services/metadata/core-properties/nuget.psmdcp",
    };

    foreach (var (tfm, target, methods) in new[]
    {
        ("net11.0-ios", "net11.0-ios27.0", new[] { "DetachController" }),
        ("net11.0-macos", "net11.0-macos27.0", new[] { "DetachController", "DetachView" }),
    })
    {
        var matchingGroups = groups.Where(group =>
            group.Attribute("targetFramework")!.Value == target).ToArray();
        Require(matchingGroups.Length == 1,
            $"NuGet dependency groups are missing or duplicate the {tfm} platform target.");
        var assemblyName = $"lib/{target}/Microsoft.SwiftUI.dll";
        var documentationName = $"lib/{target}/Microsoft.SwiftUI.xml";
        var resourceName = $"lib/{target}/Microsoft.SwiftUI.resources.zip";
        expectedEntries.Add(assemblyName);
        expectedEntries.Add(documentationName);
        expectedEntries.Add(resourceName);
        var assemblies = package.Entries.Where(entry =>
            entry.FullName == assemblyName).ToArray();
        Require(assemblies.Length == 1, $"Expected exactly one {tfm} assembly in the NuGet package.");
        var assembly = ReadEntry(assemblies[0]);
        var built = File.ReadAllBytes(Path.Combine(root, "src/Microsoft.SwiftUI/bin/Release",
            tfm, "Microsoft.SwiftUI.dll"));
        Require(assembly.AsSpan().SequenceEqual(built), $"{tfm} package assembly differs from the rebuilt Release assembly.");
        VerifyMethods(assembly, tfm, methods);

        var documentation = package.Entries.Where(entry => entry.FullName == documentationName).ToArray();
        Require(documentation.Length == 1, $"Expected exactly one {tfm} XML documentation file in the NuGet package.");
        Require(ReadEntry(documentation[0]).AsSpan().SequenceEqual(File.ReadAllBytes(
            Path.Combine(root, "src/Microsoft.SwiftUI/bin/Release", tfm, "Microsoft.SwiftUI.xml"))),
            $"{tfm} package XML documentation differs from the rebuilt Release output.");

        var resources = package.Entries.Where(entry => entry.FullName == resourceName).ToArray();
        Require(resources.Length == 1, $"Expected exactly one {tfm} native binding resource: {resourceName}");
        var resourceBytes = ReadEntry(resources[0]);
        VerifyResources(resourceBytes, tfm, frameworkFiles, reference);
        Console.WriteLine($"{tfm}: Detach API and DeactivateHost metadata verified; assembly SHA-256 {Hash(assembly)}; native resource SHA-256 {Hash(resourceBytes)}");
    }
    var actualEntries = package.Entries.Select(entry => entry.FullName).ToArray();
    Require(actualEntries.Length == expectedEntries.Count &&
            actualEntries.ToHashSet(StringComparer.Ordinal).SetEquals(expectedEntries),
        $"NuGet package entries differ from the approved payload (extra: {string.Join(", ", actualEntries.Except(expectedEntries))}; " +
        $"missing: {string.Join(", ", expectedEntries.Except(actualEntries))}).");
    foreach (var (name, source) in new[]
    {
        ("README.md", "README.md"),
        ("LICENSE", "LICENSE"),
        ("docs/ATTRIBUTION.md", "docs/ATTRIBUTION.md"),
    })
        Require(ReadEntry(package.GetEntry(name)!).AsSpan().SequenceEqual(File.ReadAllBytes(Path.Combine(root, source))),
            $"NuGet document differs from the repository: {name}");

    Console.WriteLine($"Canonical NuGet package SHA-256 {Hash(packageBytes)}: {path}");
}

static void VerifyMethods(byte[] assembly, string tfm, string[] detachMethods)
{
    using var pe = new PEReader(new MemoryStream(assembly));
    Require(pe.HasMetadata, $"{tfm} assembly has no managed metadata.");
    var reader = pe.GetMetadataReader();
    var hostType = tfm == "net11.0-ios" ? "UIKit.UIViewController" : "AppKit.NSViewController";
    foreach (var method in detachMethods)
    {
        var parameterTypes = new[] { "Microsoft.SwiftUI.SwiftView",
            method == "DetachView" ? "AppKit.NSView" : hostType };
        Require(HasMethod(reader, "Microsoft.SwiftUI", "SwiftUIHost", method,
            SignatureTypeCode.Void, parameterTypes),
            $"{tfm} assembly lacks public static SwiftUIHost.{method}({string.Join(", ", parameterTypes)}).");
    }
    Require(HasMethod(reader, "Microsoft.SwiftUI.Native", "MSUBridge", "DeactivateHost",
        SignatureTypeCode.Boolean, ["Foundation.NSObject"]),
        $"{tfm} assembly lacks public static MSUBridge.DeactivateHost(Foundation.NSObject).");
}

static bool HasMethod(MetadataReader reader, string ns, string name, string methodName,
    SignatureTypeCode returnType, string[] parameterTypes)
{
    foreach (var handle in reader.TypeDefinitions)
    {
        var type = reader.GetTypeDefinition(handle);
        if (reader.GetString(type.Namespace) != ns || reader.GetString(type.Name) != name)
            continue;
        foreach (var member in type.GetMethods())
        {
            var method = reader.GetMethodDefinition(member);
            if (reader.GetString(method.Name) != methodName ||
                (method.Attributes & MethodAttributes.MemberAccessMask) != MethodAttributes.Public ||
                !method.Attributes.HasFlag(MethodAttributes.Static))
                continue;
            var signature = reader.GetBlobReader(method.Signature);
            var header = signature.ReadSignatureHeader();
            if (header.IsGeneric || header.IsInstance ||
                signature.ReadCompressedInteger() != parameterTypes.Length ||
                signature.ReadSignatureTypeCode() != returnType)
                continue;
            var matches = true;
            foreach (var expected in parameterTypes)
                matches &= ReadParameterType(reader, ref signature) == expected;
            if (matches && signature.RemainingBytes == 0)
                return true;
        }
    }
    return false;
}

static string ReadParameterType(MetadataReader reader, ref BlobReader signature)
{
    Require(signature.ReadSignatureTypeCode() == SignatureTypeCode.TypeHandle,
        "Unexpected host-detach parameter type in managed metadata.");
    var handle = signature.ReadTypeHandle();
    return handle.Kind switch
    {
        HandleKind.TypeDefinition => TypeName(reader,
            reader.GetTypeDefinition((TypeDefinitionHandle)handle).Namespace,
            reader.GetTypeDefinition((TypeDefinitionHandle)handle).Name),
        HandleKind.TypeReference => TypeName(reader,
            reader.GetTypeReference((TypeReferenceHandle)handle).Namespace,
            reader.GetTypeReference((TypeReferenceHandle)handle).Name),
        _ => throw new InvalidDataException("Invalid host-detach parameter handle in managed metadata."),
    };
}

static string TypeName(MetadataReader reader, StringHandle ns, StringHandle name) =>
    $"{reader.GetString(ns)}.{reader.GetString(name)}";

static void VerifyResources(byte[] data, string tfm, Dictionary<string, FrameworkEntry> frameworkFiles,
    XElement reference)
{
    using var resource = new ZipArchive(new MemoryStream(data), ZipArchiveMode.Read);
    VerifyUnixZip(data, resource, $"{tfm} native resource");
    const string prefix = "MicrosoftSwiftUIShim.xcframework/";
    var found = new HashSet<string>(StringComparer.Ordinal);
    Require(resource.Entries.Count(entry => entry.FullName == "manifest") == 1,
        $"{tfm} native resource has no unique SwiftUI framework binding manifest.");
    var manifest = resource.GetEntry("manifest")!;
    Require(manifest.ExternalAttributes == unchecked((int)0x81A40000u),
        $"{tfm} native binding manifest ZIP entry is not a regular 0644 file.");
    VerifyManifest(ReadEntry(manifest), tfm, reference);
    foreach (var entry in resource.Entries)
    {
        if (entry.FullName == "manifest")
            continue;
        Require(entry.FullName.StartsWith(prefix, StringComparison.Ordinal),
            $"{tfm} native resource contains an unexpected entry: {entry.FullName}");
        var path = entry.FullName[prefix.Length..].TrimEnd('/');
        Require(found.Add(path), $"{tfm} native resource contains a duplicate framework entry: {path}");
        Require(frameworkFiles.TryGetValue(path, out var expected),
            $"{tfm} native resource contains an unknown framework entry: {path}");
        var isDirectory = expected.Kind == "directory";
        Require(entry.FullName == prefix + path + (isDirectory ? (path == "" ? "" : "/") : ""),
            $"{tfm} ZIP entry type/path differs from generated framework: {path}");
        var unixType = expected.Kind switch
        {
            "file" => 0x8000,
            "directory" => 0x4000,
            "symlink" => 0xa000,
            _ => throw new InvalidDataException($"Unsupported generated framework entry: {path}"),
        };
        var attributes = unchecked((int)((uint)((unixType | expected.Mode) << 16) |
            (isDirectory ? 0x10u : 0u)));
        Require(entry.ExternalAttributes == attributes,
            $"{tfm} ZIP entry type/attributes differ from generated framework: {path}");
        var bytes = ReadEntry(entry);
        Require(bytes.AsSpan().SequenceEqual(expected.Contents),
            $"{tfm} packaged native {(expected.Kind == "symlink" ? "symlink target" : "file")} differs from generated framework: {path}");
    }
    Require(found.SetEquals(frameworkFiles.Keys),
        $"{tfm} package is missing generated framework entries: {string.Join(", ", frameworkFiles.Keys.Except(found))}");
}

static void VerifyManifest(byte[] data, string tfm, XElement reference)
{
    var document = XDocument.Load(new MemoryStream(data));
    Require(document.Root?.Name == "BindingAssembly" && !document.Root.HasAttributes &&
            document.Root.Elements().Count() == 1 &&
            document.Root.Element("NativeReference") is not null &&
            document.Root.Nodes().OfType<XText>().All(text => string.IsNullOrWhiteSpace(text.Value)),
        $"{tfm} native binding manifest has an invalid root.");
    var native = document.Root!.Element("NativeReference");
    Require(native?.Attribute("Name")?.Value == "MicrosoftSwiftUIShim.xcframework" &&
            native.Attributes().Count() == 1 &&
            native.Nodes().OfType<XText>().All(text => string.IsNullOrWhiteSpace(text.Value)),
        $"{tfm} native binding manifest has an invalid framework name.");
    var expected = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["ForceLoad"] = "",
        ["Frameworks"] = "SwiftUI",
        ["IdentityWithoutPathSeparatorSuffix"] = "../../.build/native/MicrosoftSwiftUIShim.xcframework",
        ["IsCxx"] = "",
        ["Kind"] = "Framework",
        ["LinkerFlags"] = "",
        ["LinkWithSwiftSystemLibraries"] = "",
        ["NeedsGccExceptionHandling"] = "",
        ["SmartLink"] = reference.Element("SmartLink")?.Value ?? "",
        ["WeakFrameworks"] = "",
    };
    Require(expected["SmartLink"] is "" or "true" or "false",
        "The binding project has an invalid SmartLink setting.");
    Require(native!.Elements().Count() == expected.Count &&
            native.Elements().Select(element => element.Name)
                .ToHashSet().SetEquals(expected.Keys.Select(name => (XName)name)),
        $"{tfm} native binding manifest has missing or unexpected fields.");
    foreach (var (name, value) in expected)
    {
        var field = native.Element(name)!;
        Require(!field.HasAttributes && !field.HasElements && field.Value == value,
            $"{tfm} native binding manifest {name} differs from the binding project.");
    }
}

static void VerifyUnixZip(byte[] bytes, ZipArchive archive, string label)
{
    var data = bytes.AsSpan();
    Require(data.Length >= 22, $"{label} ZIP has no end-of-central-directory record.");
    var end = -1;
    for (var offset = data.Length - 22; offset >= Math.Max(0, data.Length - 65557); offset--)
    {
        if (BinaryPrimitives.ReadUInt32LittleEndian(data[offset..]) == 0x06054b50 &&
            offset + 22 + BinaryPrimitives.ReadUInt16LittleEndian(data[(offset + 20)..]) == data.Length)
        {
            end = offset;
            break;
        }
    }
    Require(end >= 0, $"{label} ZIP has no valid end-of-central-directory record.");
    var count = BinaryPrimitives.ReadUInt16LittleEndian(data[(end + 10)..]);
    var size = BinaryPrimitives.ReadUInt32LittleEndian(data[(end + 12)..]);
    var start = BinaryPrimitives.ReadUInt32LittleEndian(data[(end + 16)..]);
    Require(count == archive.Entries.Count && count < ushort.MaxValue &&
            (long)start + size == end, $"{label} ZIP has an invalid central directory.");
    var position = (int)start;
    foreach (var entry in archive.Entries)
    {
        Require(position + 46 <= end &&
                BinaryPrimitives.ReadUInt32LittleEndian(data[position..]) == 0x02014b50,
            $"{label} ZIP has an invalid central-directory entry.");
        // Unix mode bits only describe a file type when the entry's creating host is Unix.
        Require(data[position + 5] == 3,
            $"{label} ZIP entry host is not Unix: {entry.FullName}");
        position += 46 +
            BinaryPrimitives.ReadUInt16LittleEndian(data[(position + 28)..]) +
            BinaryPrimitives.ReadUInt16LittleEndian(data[(position + 30)..]) +
            BinaryPrimitives.ReadUInt16LittleEndian(data[(position + 32)..]);
    }
    Require(position == end, $"{label} ZIP central-directory size differs from its entries.");
}

static byte[] ReadEntry(ZipArchiveEntry entry)
{
    using var stream = entry.Open();
    using var buffer = new MemoryStream();
    stream.CopyTo(buffer);
    return buffer.ToArray();
}

static string Hash(byte[] bytes) => Convert.ToHexStringLower(SHA256.HashData(bytes));

static void Require([DoesNotReturnIf(false)] bool condition, string message)
{
    if (!condition)
        throw new InvalidDataException(message);
}

sealed record FrameworkEntry(string Kind, int Mode, byte[] Contents);

sealed record FrameworkInventory(int Version, FrameworkInventoryItem[] Entries);

sealed record FrameworkInventoryItem(string Path, string Kind, int Mode, string? Sha256, string? Target);
